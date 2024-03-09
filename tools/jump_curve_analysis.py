MAX_JUMP_TIME = 0.21

def sigmoid(x):
    """sigmoid that goes from 0 to 1 in approximately 14 ticks"""
    e = 2.73
    sigmoid_ticks = 14
    factor = sigmoid_ticks / MAX_JUMP_TIME  # ~ 66.7
    return 1/(1 + e ** -(x * factor - (sigmoid_ticks / 2)))

func = lambda x: 2 ** (-4 * x) # y = 1 at x = 0, then steep decrease until y ~= 0 at x = 1

def ticks(x):
    t = list(range(x))
    fac = (x - 1) / MAX_JUMP_TIME
    return [y / fac for y in t]

def curve(times):
    for x, prev_x in zip(times[1::], times):
        delta = x - prev_x
        yield func(x) * delta

frame_rates = [10, 30, 60, 120, 180, 500, 10000]
print([sum(curve(ticks(x))) for x in frame_rates])
print(f"max diff {abs(1 - sum(curve(ticks(30))) / sum(curve(ticks(10000)))):.2%}")
print(sum(map(func, range(14))))

# from matplotlib import pyplot as plt

# plt.
# plt.plot(list(range(14)), [sigmoid(x / 66.7) for x in range(14)])
# plt.show()
# reach 36 px height in 0.21 seconds
