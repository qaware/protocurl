import protobuf from 'protobufjs';
import http from 'http';

const PORT = 8080;

const protoFilePath = 'proto/happyday.proto';
const protoRequestPath = 'happyday.HappyDayRequest';
const protoResponsePath = 'happyday.HappyDayResponse';

let ProtobufDefs: protobuf.Root;
let HappyDayRequestType: protobuf.Type;
let HappyDayResponseType: protobuf.Type;

interface PathHandler {
    path: string;
    reqType: protobuf.Type;

    handler(reqDecoded: { [p in string]: any }): Promise<[protobuf.Type, { [p in string]: any }]>;
}

function defineHandlers(): PathHandler[] {
    return [{
        path: '/happy-day/verify',
        reqType: HappyDayRequestType,
        handler(req) {
            return Promise.resolve([HappyDayResponseType, {isHappyDay: true, reason: 'Tuesday is a Happy Day!'}]);
        }
    }];
}

function runHttpServer(handlers: PathHandler[]) {
    const requestListener: http.RequestListener = (req, res) => {
        console.log(req.method + ' ' + req.url);

        const currentHandler = handlers.find(handler => handler.path == req.url);

        if (currentHandler === undefined) {
            res.writeHead(404);
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
                    res.writeHead(200);
                    res.end(encodedMsg);
                })
                .catch(err => {
                    console.error('Error during request handling: ' + err);
                });

            await Promise.allSettled([result]);
        });
    };

    const server = http.createServer(requestListener);
    server.listen(PORT);
    console.log('Listening to port: ' + PORT);
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