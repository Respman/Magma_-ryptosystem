#! /usr/bin/env python3

import subprocess
import matplotlib.pyplot as plt
import time

def main():
    start = 0
    end = 2**15
    step = 2**10

    proc = subprocess.call("./init.sh", shell = True)

    out = [[],[]]
    for i in range(start, (end+1), step):
        sum1 = 0
        sum2 = 0
        for j in range(30):
            string = 'A'*i
            cmd = f"echo {string} > ./1.txt"
            proc = subprocess.call(cmd, shell = True)

            cmd = "./ECB_c.out ./1.txt ./2.txt ffeeddccbbaa99887766554433221100f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff"

            cur_time1 = -int(time.time()*1000)
            proc = subprocess.call(cmd, shell = True)
            cur_time1 += int(time.time()*1000)
            sum1 += cur_time1

            cmd = "./ECB_asm.out ./1.txt ./3.txt ffeeddccbbaa99887766554433221100f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff"
            cur_time2 = -int(time.time()*1000)
            proc = subprocess.call(cmd, shell = True)
            cur_time2 += int(time.time()*1000)
            sum2 += cur_time2

        out[1].append(sum2/30)
        out[0].append(sum1/30)


    x = [i for i in range(start, (end+1), step)]

    fig, ax = plt.subplots(figsize=(5,3))
    ax.plot(x, out[1], color = "green", label = "asm")
    ax.plot(x, out[0], color = "red", label = "C")
    ax.set_title('Сравнение скорости вычисления блочного шифра магма')
    ax.legend(loc = 'upper left')
    ax.set_ylabel('time, ms')
    ax.set_xlabel('number of open text')
    ax.set_xlim(xmin = x[0], xmax = x[-1])
    fig.tight_layout()

    plt.show()

if __name__ == "__main__":
    main()
