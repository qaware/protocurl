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

interface PathHandler {
    path: string;
    reqType: protobuf.Type;

    handler(reqDecoded: { [p in string]: any }): Promise<[protobuf.Type, { [p in string]: any }]>;
}

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

            return [HappyDayResponseType, {
                isHappyDay,
                reason: isHappyDay ? (formattedWeekday + ' is a Happy Day! ⭐') : ('Tough luck on ' + formattedWeekday + '... 😕'),
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
    const requestListener: http.RequestListener = (req, res) => {
        console.log('=========== ' + req.method + ' ' + req.url);

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