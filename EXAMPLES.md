# Examples

After starting the local test server via `docker-compose -f test/servers/compose.yml up --build server`, you can send
the following list of requests via protoCURL.

Each request needs to mount the directory of proto files into the containers `/proto` path to ensure, that they are
visible inside the docker container.

```
$ docker run -v "$PWD/test/proto:/proto" --network host protocurl \
   -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \
   -u http://localhost:8080/happy-day/verify \
   -d "includeReason: true"

=========================== Request Text     =========================== >>>
includeReason:  true
=========================== Response Text    =========================== <<<
isHappyDay:  true
reason:  "Thursday is a Happy Day! ⭐"
formattedDate:  "Thu, 01 Jan 1970 00:00:00 GMT"
```

```
$ docker run -v "$PWD/test/proto:/proto" --network host protocurl \
  -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \
  -u http://localhost:8080/happy-day/verify -d ""

=========================== Request Text     =========================== >>>

=========================== Response Text    =========================== <<<
isHappyDay:  true
formattedDate:  "Thu, 01 Jan 1970 00:00:00 GMT"
```

```
$ docker run -v "$PWD/test/proto:/proto" --network host protocurl \
  -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \
  -u http://localhost:8080/happy-day/verify \
  -d "date: { seconds: 1648044939}"

=========================== Request Text     =========================== >>>
date:  {
  seconds:  1648044939
}
=========================== Response Text    =========================== <<<
formattedDate:  "Wed, 23 Mar 2022 14:15:39 GMT"
```

Use `-v` for verbose output:

```
$ docker run -v "$PWD/test/proto:/proto" --network host protocurl \
  -v -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \
  -u http://localhost:8080/happy-day/verify \
  -d "date: { seconds: 1648044939}"

protocurl todo, build todo
Adding default header argument to request headers : [-H 'Content-Type: application/x-protobuf']
Invoked with following default & parsed arguments:
{
  "ProtoFilesDir": "/proto",
  "ProtoInputFilePath": "happyday.proto",
  "RequestType": "happyday.HappyDayRequest",
  "ResponseType": "happyday.HappyDayResponse",
  "Url": "http://localhost:8080/happy-day/verify",
  "DataText": "date: { seconds: 1648044939}",
  "DisplayBinaryAndHttp": true,
  "RequestHeaders": [
    "-H",
    "'Content-Type: application/x-protobuf'"
  ],
  "CustomCurlPath": "",
  "AdditionalCurlArgs": "",
  "Verbose": true,
  "ShowOutputOnly": false,
  "ForceNoCurl": false,
  "ForceCurl": false,
  "GlobalProtoc": false,
  "CustomProtocPath": ""
}
Found bundled protoc at /protocurl/protocurl-internal/bin/protoc
Using google protobuf include: /protocurl/protocurl-internal/include
=========================== .proto descriptor ===========================
file:  {
  name:  "google/protobuf/timestamp.proto"
  package:  "google.protobuf"
  message_type:  {
    name:  "Timestamp"
    field:  {
      name:  "seconds"
      number:  1
      label:  LABEL_OPTIONAL
      type:  TYPE_INT64
      json_name:  "seconds"
    }
    field:  {
      name:  "nanos"
      number:  2
      label:  LABEL_OPTIONAL
      type:  TYPE_INT32
      json_name:  "nanos"
    }
  }
  options:  {
    java_package:  "com.google.protobuf"
    java_outer_classname:  "TimestampProto"
    java_multiple_files:  true
    go_package:  "google.golang.org/protobuf/types/known/timestamppb"
    cc_enable_arenas:  true
    objc_class_prefix:  "GPB"
    csharp_namespace:  "Google.Protobuf.WellKnownTypes"
  }
  syntax:  "proto3"
}
file:  {
  name:  "happyday.proto"
  package:  "happyday"
  dependency:  "google/protobuf/timestamp.proto"
  message_type:  {
    name:  "HappyDayRequest"
    field:  {
      name:  "date"
      number:  1
      label:  LABEL_OPTIONAL
      type:  TYPE_MESSAGE
      type_name:  ".google.protobuf.Timestamp"
      json_name:  "date"
    }
    field:  {
      name:  "includeReason"
      number:  2
      label:  LABEL_OPTIONAL
      type:  TYPE_BOOL
      json_name:  "includeReason"
    }
    field:  {
      name:  "double"
      number:  3
      label:  LABEL_OPTIONAL
      type:  TYPE_DOUBLE
      json_name:  "double"
    }
    field:  {
      name:  "int32"
      number:  4
      label:  LABEL_OPTIONAL
      type:  TYPE_INT32
      json_name:  "int32"
    }
    field:  {
      name:  "int64"
      number:  5
      label:  LABEL_OPTIONAL
      type:  TYPE_INT64
      json_name:  "int64"
    }
    field:  {
      name:  "string"
      number:  6
      label:  LABEL_OPTIONAL
      type:  TYPE_STRING
      json_name:  "string"
    }
    field:  {
      name:  "bytes"
      number:  7
      label:  LABEL_OPTIONAL
      type:  TYPE_BYTES
      json_name:  "bytes"
    }
    field:  {
      name:  "fooEnum"
      number:  8
      label:  LABEL_OPTIONAL
      type:  TYPE_ENUM
      type_name:  ".happyday.Foo"
      json_name:  "fooEnum"
    }
    field:  {
      name:  "misc"
      number:  9
      label:  LABEL_REPEATED
      type:  TYPE_MESSAGE
      type_name:  ".happyday.MiscInfo"
      json_name:  "misc"
    }
    field:  {
      name:  "float"
      number:  10
      label:  LABEL_OPTIONAL
      type:  TYPE_FLOAT
      json_name:  "float"
    }
  }
  message_type:  {
    name:  "HappyDayResponse"
    field:  {
      name:  "isHappyDay"
      number:  1
      label:  LABEL_OPTIONAL
      type:  TYPE_BOOL
      json_name:  "isHappyDay"
    }
    field:  {
      name:  "reason"
      number:  2
      label:  LABEL_OPTIONAL
      type:  TYPE_STRING
      json_name:  "reason"
    }
    field:  {
      name:  "formattedDate"
      number:  3
      label:  LABEL_OPTIONAL
      type:  TYPE_STRING
      json_name:  "formattedDate"
    }
    field:  {
      name:  "err"
      number:  4
      label:  LABEL_OPTIONAL
      type:  TYPE_STRING
      json_name:  "err"
    }
  }
  message_type:  {
    name:  "MiscInfo"
    field:  {
      name:  "weatherOfPastFewDays"
      number:  1
      label:  LABEL_REPEATED
      type:  TYPE_STRING
      json_name:  "weatherOfPastFewDays"
    }
    field:  {
      name:  "fooString"
      number:  2
      label:  LABEL_OPTIONAL
      type:  TYPE_STRING
      oneof_index:  0
      json_name:  "fooString"
    }
    field:  {
      name:  "fooEnum"
      number:  3
      label:  LABEL_OPTIONAL
      type:  TYPE_ENUM
      type_name:  ".happyday.Foo"
      oneof_index:  0
      json_name:  "fooEnum"
    }
    oneof_decl:  {
      name:  "alternative"
    }
  }
  enum_type:  {
    name:  "Foo"
    value:  {
      name:  "BAR"
      number:  0
    }
    value:  {
      name:  "BAZ"
      number:  1
    }
    value:  {
      name:  "FAZ"
      number:  2
    }
  }
  syntax:  "proto3"
}
=========================== Request Text     =========================== >>>
date:  {
  seconds:  1648044939
}
=========================== Request Binary   =========================== >>>
00000000  0a 06 08 8b d7 ec 91 06                           |........|
Found curl: /usr/bin/curl
Invoking curl http request.
Understood additional curl args: []
=========================== Response Headers =========================== <<<
HTTP/1.1 200 OK
Content-Type: application/x-protobuf
Date: Sat, 09 Apr 2022 23:12:10 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Content-Length: 35
=========================== Response Binary  =========================== <<<
00000000  08 00 1a 1d 57 65 64 2c  20 32 33 20 4d 61 72 20  |....Wed, 23 Mar |
00000010  32 30 32 32 20 31 34 3a  31 35 3a 33 39 20 47 4d  |2022 14:15:39 GM|
00000020  54 22 00                                          |T".|
=========================== Response Text    =========================== <<<
formattedDate:  "Wed, 23 Mar 2022 14:15:39 GMT"
```
