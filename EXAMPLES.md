# iosMath Examples

## Square of sums
```LaTeX
(a_1 + a_2)^2 = a_1^2 + 2a_1a_2 + a_2^2
```

![Square Formula](img/square.png)

## Quadratic Formula
```LaTeX
x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}
```

![Quadratic Formula](img/quadratic.png)

## Standard Deviation
```LaTeX
\sigma = \sqrt{\frac{1}{N}\sum_{i=1}^N (x_i - \mu)^2}
```
![Standard Deviation](img/standard.png)

## De Morgan's laws
```LaTeX
\neg(P\land Q) \iff (\neg P)\lor(\neg Q)
```

![De Morgan](img/demorgan.png)

## Log Change of Base
```LaTeX
\log_b(x) = \frac{\log_a(x)}{\log_a(b)}
```

![Log Base Change](img/log.png)

## Cosine addition
```LaTeX
\cos(\theta + \varphi) = \cos(\theta)\cos(\varphi) - \sin(\theta)\sin(\varphi)
```

![Cos Sum](img/trig.png)

## Limit e^k
```LaTeX
\lim_{x\to\infty}\left(1 + \frac{k}{x}\right)^x = e^k
```

![Limit](img/limit.png)

## Calculus
```LaTeX
f(x) = \int\limits_{-\infty}^\infty\!\hat f(\xi)\,e^{2 \pi i \xi x}\,\mathrm{d}\xi
```

![Calculus](img/calculus.png)

## Stirling Numbers of the Second Kind
```LaTeX
{n \brace k} = \frac{1}{k!}\sum_{j=0}^k (-1)^{k-j}\binom{k}{j}(k-j)^n
```

![Stirling Numbers](img/stirling.png)

## Gaussian Integral
```LaTeX
\int_{-\infty}^{\infty} \! e^{-x^2} dx = \sqrt{\pi}
```

![Gauss Integral](img/gaussintegral.png)

## Arithmetic mean, geometric mean inequality
```LaTeX
\frac{1}{n}\sum_{i=1}^{n}x_i \geq \sqrt[n]{\prod_{i=1}^{n}x_i}
```

![AM-GM](img/amgm.png)

## Cauchy-Schwarz inequality
```LaTeX
\left(\sum_{k=1}^n a_k b_k \right)^2 \le \left(\sum_{k=1}^n a_k^2\right)\left(\sum_{k=1}^n b_k^2\right)
```
![Cauchy Schwarz](img/cauchyschwarz.png)

## Cauchy integral formula
```LaTeX
f^{(n)}(z_0) = \frac{n!}{2\pi i}\oint_\gamma\frac{f(z)}{(z-z_0)^{n+1}}dz
```

![Cauchy Integral](img/cauchyintegral.png)
## Schroedinger's Equation
```LaTeX
i\hbar\frac{\partial}{\partial t}\mathbf\Psi(\mathbf{x},t) = -\frac{\hbar}{2m}\nabla^2\mathbf\Psi(\mathbf{x},t)
+ V(\mathbf{x})\mathbf\Psi(\mathbf{x},t)
```

![Schroedinger](img/schroedinger.png)

## Lorentz Equations
Use the `gather` or `displaylines` environments to center multiple
equations. `gathered` is the nestable variant, usable inside another
formula.
```LaTeX
\begin{gather}
\dot{x} = \sigma(y-x) \\
\dot{y} = \rho x - y - xz \\
\dot{z} = -\beta z + xy
\end{gather}
```

![Lorentz](img/lorentz.png)

## Cross product
```LaTeX
\vec \bf V_1 \times \vec \bf V_2 =  \begin{vmatrix}
\hat \imath &\hat \jmath &\hat k \\
\frac{\partial X}{\partial u} & \frac{\partial Y}{\partial u} & 0 \\
\frac{\partial X}{\partial v} & \frac{\partial Y}{\partial v} & 0
\end{vmatrix}
```

![Cross Product](img/cross.png)

## Maxwell's Equations
Use the `aligned`, `eqalign` or `split` environments to align
multiple equations.
```LaTeX
\begin{eqalign}
\nabla \cdot \vec{\bf E} & = \frac {\rho} {\varepsilon_0} \\
\nabla \cdot \vec{\bf B} & = 0 \\
\nabla \times \vec{\bf E} &= - \frac{\partial\vec{\bf B}}{\partial t} \\
\nabla \times \vec{\bf B} & = \mu_0\vec{\bf J} + \mu_0\varepsilon_0 \frac{\partial\vec{\bf E}}{\partial t}
\end{eqalign}
```

![Maxwell's Equations](img/maxwell.png)

## Matrix multiplication
Supported matrix environments: `matrix`, `pmatrix`, `bmatrix`, `Bmatrix`,
`vmatrix`, `Vmatrix`, and `smallmatrix` (a compact, script-sized matrix for
inline use).
```LaTeX
\begin{pmatrix}
a & b\\ c & d
\end{pmatrix}
\begin{pmatrix}
\alpha & \beta \\ \gamma & \delta
\end{pmatrix} = 
\begin{pmatrix}
a\alpha + b\gamma & a\beta + b \delta \\
c\alpha + d\gamma & c\beta + d \delta 
\end{pmatrix}
```

![Matrix Multiplication](img/matrixmult.png)

## Cases
```LaTeX
f(x) = \begin{cases}
\frac{e^x}{2} & x \geq 0 \\
1 & x < 0
\end{cases}
```

![Cases](img/cases.png)

## Splitting long equations
```LaTeX
\frak Q(\lambda,\hat{\lambda}) =
-\frac{1}{2} \mathbb P(O \mid \lambda ) \sum_s \sum_m \sum_t \gamma_m^{(s)} (t) +\\
\quad \left( \log(2 \pi ) + \log \left| \cal C_m^{(s)} \right| +
\left( o_t - \hat{\mu}_m^{(s)} \right) ^T \cal C_m^{(s)-1} \right) 
```

![Long equation](img/long.png)

---

# More supported features

The examples below showcase additional supported commands. They mirror the
runnable gallery in [`MathExamples.h`](./MathExamples.h) (shared by the iOS,
macOS, and SwiftUI example apps); preview images are not included here.

## AMS fraction and binomial macros
`\dfrac` / `\tfrac` force display / text style; `\cfrac` builds continued
fractions; `\dbinom` / `\tbinom` are the display / text binomials.
```LaTeX
\tfrac{1}{2} + \dfrac{1}{2} = \cfrac{1}{1+\cfrac{1}{1+\cfrac{1}{1}}}
\qquad \dbinom{n}{k} \quad \tbinom{n}{k}
```

## Explicitly sized delimiters
`\big`, `\Big`, `\bigg`, `\Bigg` (with `l` / `r` / `m` class variants) set a
fixed delimiter size, independent of the content-driven `\left … \right`.
```LaTeX
\bigl( x + y \bigr) \quad \Bigl[ z \Bigr] \quad
\biggl\langle w \biggr\rangle \quad a \bigm| b
```

## Stacked and annotated relations
`\overset`, `\underset`, `\stackrel`, and `\stackbin` place a symbol above or
below a base while keeping the correct spacing class.
```LaTeX
f(x) \stackrel{\text{def}}{=} \sum_{n=0}^{\infty} \frac{f^{(n)}(0)}{n!} x^n
\qquad \underset{x \in \mathbb{R}}{\sup}\, f(x)
```

## Over/under braces and arrows
```LaTeX
\overbrace{a+b+c}^{n} + \underbrace{d+e+f}_{m}
\qquad \overrightarrow{AB} \cdot \overleftarrow{CD}
```

## Multiple integrals
```LaTeX
\iint_S f \, dA = \iiint_V g \, dV = \iiiint_{\mathbb{R}^4} h \, dV
```

## Compact inline matrices
`smallmatrix` renders script-sized cells for use inside a line of math.
```LaTeX
A^{-1} = \frac{1}{ad-bc}\left(\begin{smallmatrix} d & -b \\ -c & a \end{smallmatrix}\right)
```

## Nestable centered equations
`gathered` centers a stack of equations and, unlike `gather`, can be nested
inside another formula.
```LaTeX
\begin{gathered}
(a+b)^2 = a^2 + 2ab + b^2 \\
(a-b)^2 = a^2 - 2ab + b^2
\end{gathered}
```

## Colors
`\color` recolors an expression; `\colorbox` fills the background behind it.
```LaTeX
\color{#ff3399}{(a_1+a_2)^2} = a_1^2 + 2a_1a_2 + a_2^2
\qquad \colorbox{#f0f0e0}{\sqrt{1+x}}
```
