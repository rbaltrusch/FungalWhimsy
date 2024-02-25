import random

factors = [
    (random.randint(8, 32), random.randint(-50, 350), random.randint(-50, 250))
    for _ in range(15)
]
print(
    ", ".join(
        ["{" + ", ".join(map(str, x)) + "}" for x in sorted(factors, reverse=True)]
    )
)
