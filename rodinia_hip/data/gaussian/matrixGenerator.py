#!/usr/bin/env python3

import random
import sys


def main():
    start = 4
    end = 4
    step = 1

    # 参数解析：
    # python3 matrixGenerator.py             -> 生成 matrix4.txt
    # python3 matrixGenerator.py 64          -> 生成 matrix64.txt
    # python3 matrixGenerator.py 16 256      -> 生成 matrix16.txt ... matrix256.txt，步长为 1
    # python3 matrixGenerator.py 16 256 16   -> 生成 matrix16.txt, matrix32.txt, ... matrix256.txt
    try:
        if len(sys.argv) >= 2:
            start = int(sys.argv[1])
            end = start

        if len(sys.argv) >= 3:
            end = int(sys.argv[2])

        if len(sys.argv) >= 4:
            step = int(sys.argv[3])

    except ValueError:
        print("Usage:")
        print("  python3 matrixGenerator.py")
        print("  python3 matrixGenerator.py <size>")
        print("  python3 matrixGenerator.py <start> <end> <step>")
        sys.exit(1)

    if step <= 0:
        print("Error: step must be positive.")
        sys.exit(1)

    for size in range(start, end + 1, step):
        print(f"Generating matrix{size}.txt")

        soln_vec = []
        matrix = []
        b_vector = []

        filename = f"matrix{size}.txt"

        # 随机生成解向量，范围 [-1.0, 1.0]
        for _ in range(size):
            soln_vec.append(random.randint(-10, 10) / 10.0)

        # 随机生成系数矩阵，范围 [-1.0, 1.0]
        for _ in range(size):
            matrix_row = []
            for _ in range(size):
                matrix_row.append(random.randint(-10, 10) / 10.0)
            matrix.append(matrix_row)

        with open(filename, "w", encoding="utf-8") as f:
            # 第一行写矩阵规模
            f.write(f"{size}\n\n")

            # 写 n x n 矩阵，同时计算 b 向量
            for row in matrix:
                lin_result = 0.0

                for j in range(size):
                    f.write(f"{row[j]}\t")
                    lin_result += row[j] * soln_vec[j]

                b_vector.append(lin_result)
                f.write("\n")

            # 写 b 向量
            f.write("\n")
            for value in b_vector:
                f.write(f"{value}\t")

            # 写理论解向量
            f.write("\n\n")
            for value in soln_vec:
                f.write(f"{value}\t")

            f.write("\n\n")


if __name__ == "__main__":
    main()