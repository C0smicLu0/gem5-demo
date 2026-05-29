#include <iostream>
#include <fstream>
#include <string>
#include <cstdlib>

using namespace std;

/*
 * Usage:
 *   ./create.out 2048
 *   ./create.out 2048 2048
 *   ./create.out 2048 2048 2048.rgb
 *
 * Default:
 *   width = 192
 *   height = 192
 *   fileName = "192.rgb"
 *
 * Output format:
 *   raw RGB, 3 bytes per pixel, row-major
 *   pixel(x,y) = [R, G, B]
 */

static void writeRGB(const string &fileName, int width, int height)
{
    ofstream ofs(fileName.c_str(), ios::binary);
    if (!ofs) {
        cerr << "Failed to open output file: " << fileName << endl;
        exit(1);
    }

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            unsigned char r = (unsigned char)((x + y) & 255);
            unsigned char g = (unsigned char)((2 * x + y) & 255);
            unsigned char b = (unsigned char)((x + 2 * y) & 255);

            ofs.write((char *)&r, 1);
            ofs.write((char *)&g, 1);
            ofs.write((char *)&b, 1);
        }
    }

    ofs.close();
    if (!ofs) {
        cerr << "Failed while writing output file: " << fileName << endl;
        exit(1);
    }
}

int main(int argc, char **argv)
{
    int width = 192;
    int height = 192;
    string fileName = "192.rgb";

    if (argc == 2) {
        width = atoi(argv[1]);
        height = width;
        fileName = string(argv[1]) + ".rgb";
    } else if (argc == 3) {
        width = atoi(argv[1]);
        height = atoi(argv[2]);
        fileName = string(argv[1]) + "x" + string(argv[2]) + ".rgb";
    } else if (argc >= 4) {
        width = atoi(argv[1]);
        height = atoi(argv[2]);
        fileName = argv[3];
    }

    if (width <= 0 || height <= 0) {
        cerr << "Invalid image size: " << width << "x" << height << endl;
        return 1;
    }

    cout << "Generating raw RGB file: " << fileName << endl;
    cout << "Size: " << width << "x" << height << endl;
    cout << "Expected bytes: " << (long long)width * height * 3 << endl;

    writeRGB(fileName, width, height);

    cout << "Successfully wrote file: [" << fileName << "]" << endl;
    return 0;
}