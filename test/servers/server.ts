import protobuf from 'protobufjs';
import http from 'http';
import Long from 'long';

const PORT = 8080;

const protoFilePath = 'proto/happyday.proto';
const protoRequestPath = 'happyday.HappyDayRequest';
const protoResponsePath = 'happyday.HappyDayResponse';

let ProtobufDefs: protobuf.Root;
let HappyDayRequestType: protobuf.Type;
let HappyDayResponseType: protobuf.Type;

const weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const wednesdayDateWeekday = 3;

// these would be usually automatically generated
interface HappyDayRequest {
    date: {
        seconds: Long;
        nanos: number;
    };
    includeReason: boolean;
}

interface HappyDayResponse {
    isHappyDay: boolean;
    reason: string;
    formattedDate: string;
    err: string;
}

/** A path handler specifies the path (e.g. /happy-day/verify) on which it acts.
 * If the corresponding path is requested, then runHttpServer(...) parses the body into the
 * reqType protobuf message type and runs the handler method to generate the response.
 * The handler returns the protobuf message output type - which the http server uses to serialise the response.
 */
interface PathHandler {
    path: string;
    reqType: protobuf.Type;

    handler(reqDecoded: { [p in string]: any }): Promise<[protobuf.Type, { [p in string]: any }]>;
}

/**
 * Defines two paths.
 *
 * <p>The path `/happy-day/verify` takes an HappyDayRequest and tells us, whether the
 * given date is a happy one. (Every day except Wednesday is defined to be happy, doh).
 * If the specified date is too far in the future for the epochMillis in javascript
 * to handle, then an error is returned to the `err` field. Additionally, the date used
 * is formatted to a string and additionally a "reason" is given, if requested.
 *
 * <p> The path `/echo` simply returns the input body back.
 */
function defineHandlers(): PathHandler[] {
    return [{
        path: '/happy-day/verify',
        reqType: HappyDayRequestType,
        async handler(req: HappyDayRequest) {
            let err = '';

            const date = req?.date ?? {seconds: new Long(0, 0), nanos: 0};
            const seconds = date.seconds;
            const nanos = date.nanos;

            const epochMillis = seconds.mul(1000).add(Math.floor(nanos / 1000 / 1000));

            const epochMillisNumber = epochMillis.toNumber();

            if (epochMillis.toString() !== epochMillisNumber.toString()) {
                return [HappyDayResponseType, {err: err + 'Cannot handle number of millis ' + epochMillis + ' as number: ' + epochMillisNumber + '\n'}];
            }

            const jsDate = new Date(epochMillisNumber);

            const dateWeekday = jsDate.getUTCDay();
            const formattedWeekday = weekdays[dateWeekday];

            console.log('Weekday is ' + dateWeekday + ', ' + formattedWeekday);

            const isHappyDay = dateWeekday !== wednesdayDateWeekday;

            const reason = isHappyDay ? (formattedWeekday + ' is a Happy Day! ⭐') : ('Tough luck on ' + formattedWeekday + '... 😕');

            return [HappyDayResponseType, {
                isHappyDay,
                reason: req.includeReason ? reason : undefined,
                formattedDate: jsDate.toUTCString(),
                err,
            } as HappyDayResponse];
        }
    },
        {
            path: '/echo',
            reqType: HappyDayRequestType,
            async handler(reqDecoded: { [p in string]: any }): Promise<[protobuf.Type, { [p in string]: any }]> {
                return [HappyDayRequestType, reqDecoded];
            }
        }
    ];
}

function runHttpServer(handlers: PathHandler[]) {

    /** The request listener accepts the incoming requests. If a path not found in the handlers is requested,
     * then it returns 404. Otherwise, it invokes the corresponding handler, by converting the
     * binary protobuf request body into the protobuf message and using the handlers' invocation method.
     * If the handler returns a successful promise, the request listener converts it back to binary and sends it
     * as the response body. Otherwise, the error is logged and a 500 is returned.
     * */
    const requestListener: http.RequestListener = (req, res) => {
        console.log('=========== ' + req.method + ' ' + req.url);
        console.log(req.rawHeaders.map(s => '  ' + s));

        const currentHandler = handlers.find(handler => handler.path == req.url);

        if (currentHandler === undefined) {
            req.statusCode = 404;
            res.end();
            return;
        }

        let buffers: any[] = [];
        req.on('data', chunk => {
            buffers.push(chunk);
        });

        req.on('end', async () => {
            const data = Buffer.concat(buffers);
            console.log('Extracted body: Base64(' + data.toString('base64') + '), Binary(' + data + ')');

            const result = new Promise<protobuf.Message>((resolve, reject) => {
                try {
                    const decodedMsg = currentHandler.reqType.decode(data);
                    console.log('Decoded request: ' + JSON.stringify(decodedMsg, null, 2));
                    resolve(decodedMsg);
                } catch (err) {
                    reject(err);
                }
            })
                .then(decodedMsg => currentHandler.handler(decodedMsg))
                .then(([responseType, respMessage]) => {
                    console.log('Encoding response: ' + JSON.stringify(respMessage, null, 2));
                    const encodedMsg = responseType.encode(respMessage).finish();
                    res.statusCode = 200;
                    res.setHeader('Content-Type', 'application/x-protobuf');
                    res.end(encodedMsg);
                    console.log('=========== 200 OK');
                })
                .catch(err => {
                    console.error('Error during request handling: ');
                    console.error(err);
                    res.statusCode = 500;
                    res.end();
                });

            await Promise.allSettled([result]);
        });
    };

    const server = http.createServer(requestListener);
    server.listen(PORT);
    console.log('Listening to port: ' + PORT); // This line is used in the test runner to detect readiness
}

protobuf.load(protoFilePath)
    .then(root => {
        ProtobufDefs = root;
        HappyDayRequestType = ProtobufDefs.lookupType(protoRequestPath);
        HappyDayResponseType = ProtobufDefs.lookupType(protoResponsePath);
        return undefined;
    })
    .then(defineHandlers)
    .then(handlers => runHttpServer(handlers));