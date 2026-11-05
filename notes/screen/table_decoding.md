| config | GSM8K completion | GSM8K acc | GSM8K loop-end | MATH-500 completion | MATH-500 acc | MATH-500 loop-end | mean tokens (GSM8K / MATH) |
|---|---|---|---|---|---|---|---|
| base, thinking on | 0.12 | 0.147 | 0.86 | 0.07 | 0.072 | 0.86 | 14983 / 15630 |
| **p50c, thinking on** | 0.76 | 0.570 | 0.07 | 0.34 | 0.312 | 0.09 | 9964 / 13759 |
| **base, thinking off** | 0.99 | 0.555 | 0.00 | 0.83 | 0.512 | 0.05 | 1513 / 5995 |
| base, repetition penalty 1.1 | 0.47 | 0.410 | 0.43 | 0.21 | 0.200 | 0.44 | 11805 / 14278 |
| base, repetition penalty 1.2 | 0.31 | 0.010 | 0.38 | 0.24 | 0.013 | 0.39 | 12935 / 13708 |
| base, thinking budget 4k (forced </think>) | 0.57 | 0.517 | 0.41 | 0.33 | 0.315 | 0.60 | 9531 / 12526 |
| base, thinking budget 8k | 0.58 | 0.537 | 0.41 | 0.35 | 0.343 | 0.55 | 11461 / 13475 |
