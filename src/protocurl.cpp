
#include <iostream>

#include <google/protobuf/compiler/importer.h> // installed in /usr/local/include and automatically resolved

using namespace google::protobuf::compiler;
using namespace google::protobuf;

// c++ installation instructions inside ubuntu container: https://github.com/protocolbuffers/protobuf/blob/main/src/README.md

// apt install pkg-config
// c++ -std=c++11 -O1 src/protocurl.cpp -v -o src/protocurl `pkg-config --cflags --libs protobuf`

/* cross compilation:
https://groups.google.com/g/protobuf/c/9_98Rhm8QGY?pli=1
https://groups.google.com/g/protobuf/c/wlAWIT3RZL0

*/

class MyErrorCollector : public MultiFileErrorCollector {
    public:
        MyErrorCollector() {};
        ~MyErrorCollector() override {};

    std::string text_;

    // implements ErrorCollector ---------------------------------------
    void AddError(const std::string& filename, int line, int column,
                const std::string& message) override {
                std::cout << "Error: " << filename << ", " << line << ", " << column << ", " << message << std::endl;
    //    strings::SubstituteAndAppend(&text_, "$0:$1:$2: $3\n", filename, line, column,
    //                              message);
  }
};

int main(int argc, char* argv[]) {

    DiskSourceTree srcTree;

    srcTree.MapPath("/proto","/app/test/proto");
    srcTree.MapPath("google/protobuf","/app/lib/protobuf-3.19.4/src/google/protobuf");

    {
        std::string diskPath;
        bool success = srcTree.VirtualFileToDiskFile("/proto/happyday.proto", &diskPath);
        std::cout << "success: " << success << std::endl;
        std::cout << "resolved disk path: " << diskPath << std::endl;
    }

    {
        std::string diskPath;
        bool success = srcTree.VirtualFileToDiskFile("google/protobuf/timestamp.proto", &diskPath);
        std::cout << "success: " << success << std::endl;
        std::cout << "resolved disk path: " << diskPath << std::endl;
    }

    MyErrorCollector errorCollector;

    Importer myImporter(&srcTree, &errorCollector);

    const FileDescriptor* fileDesc = myImporter.Import("/proto/happyday.proto");

    int nEnums = fileDesc->enum_type_count();

    std::cout << nEnums << std::endl;

    std::cout << "Hello World" << std::endl;
}