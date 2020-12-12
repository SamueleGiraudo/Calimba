# Author: Samuele Giraudo
# Creation: aug. 2020
# Modifications: aug. 2020

# PCM visualizer.

import sys
import matplotlib.pyplot as plt

print("Usage: python Graph.py PATH RATE DEPTH DURATION")
print("Start.")

path = sys.argv[1]
rate = int(sys.argv[2])
depth = int(sys.argv[3])
duration = float(sys.argv[4])

f = open(path, "rb")
max_val = 2 ** (8 * depth - 1) - 1
length = duration * rate

points = []
nb = 0
while byte := f.read(depth):
    val = int.from_bytes(byte, byteorder = "little", signed = True) / max_val
    points.append(val)
    nb += 1
    if nb == length:
        break

plt.plot(points)
plt.title("Sound")
plt.xlabel("Time (sec)")
plt.ylabel("Amplitude")
plt.grid(True)

duration = len(points) // rate
tick_locs = [x * rate for x in range(duration)]
tick_lbls = range(duration)
plt.xticks(tick_locs, tick_lbls)

plt.savefig("Graph.svg")
plt.savefig("Graph.jpg")
plt.show()

print("End.")

