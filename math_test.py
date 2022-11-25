import matplotlib.pyplot as plt
import numpy as np

def check():
    s = 0
    for i in range(12):
        f = 1/(2**i)
        if s + f < 0.1:
            s = s + f
            print(i, f)

def check_heuristic():
    def bin_div_10(v):
        return v // 16 + v // 32 + 1

    values = np.arange(0, 256, 1)
    plt.plot(values, values / 10)
    plt.plot(values, bin_div_10(values))
    plt.show()

def rrf(v, c_in = 0):
    c_out = v & 1
    v = (v >> 1) + (c_in * 128)
    return v, c_out

def rlf(v, c_in = 0):
    c_out = bool(v & 128)
    v = ((v << 1) & 255) + (c_in * 1)
    return v, c_out

def swapf(v):
    return ((v >> 4) + ((v << 4) & 255))

def check_2():

    def bin_div_10(f):

        w = f
        
        f, _ = rrf(f)

        f = f + w

        f, _ = rrf(f)
        f, _ = rrf(f)
        f, _ = rrf(f)

        f = f + w

        f, _ = rrf(f)

        f = w + f
        c = ((f & 256) != 0)
        f = f & 255

        w = swapf(f)
        w = w & 15
        f = w

        f = f | (16 * (c == 1))

        return f

    print(bin_div_10(11))
    # return

    values = np.arange(0, 256, 1)
    plt.plot(values, np.floor(values / 10))
    plt.plot(values, bin_div_10(values))
    # plt.plot(values, np.floor(values * (1/16 + 1/32 + 1/256 + 1/512)))
    plt.show()

def get_8bit_binary(v):
    return f"{v:08b}"

def twos_comp(n):
    bin = get_8bit_binary(n)\
        .replace("0", "Z").replace("1", "0").replace("Z", "1")
    return int(bin, base=2) + 1

def check_minus():
    first = 9
    minus = 12

    print()
    print("   " + get_8bit_binary(first), end="")
    print(f" ({first})")
    print(" - " + get_8bit_binary(twos_comp(minus)), end="")
    print(f" ({minus})")
    print("   --------")
    print(f"  {get_8bit_binary(first + twos_comp(minus)):>9s}", end="")
    print(f" ({first + twos_comp(minus)})")
    print()

if __name__ == "__main__":
    check_2()
