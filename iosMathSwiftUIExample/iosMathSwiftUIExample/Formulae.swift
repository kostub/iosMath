//
//  Formulae.swift
//  iosMathSwiftUIExample
//
//  Demo and test LaTeX formulae ported from iosMathExample/ViewController.m.
//

import UIKit

struct FormulaItem: Identifiable {
    let id = UUID()
    let latex: String
    let height: CGFloat
    var fontSize: CGFloat = 15
    var backgroundColor: UIColor = .clear
    var alignment: MathAlignment = .left
    var mode: MathMode = .display
    var contentInsets: UIEdgeInsets = .zero
}

enum Formulae {
    static let tintedBackground = UIColor(hue: 0.15, saturation: 0.2, brightness: 1.0, alpha: 1.0)

    static let demoFormulae: [FormulaItem] = [
        FormulaItem(
            latex: #"\text{ваш вопрос: }x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}"#,
            height: 60),
        FormulaItem(
            latex: #"\color{#ff3399}{(a_1+a_2)^2}=a_1^2+2a_1a_2+a_2^2"#,
            height: 40),
        FormulaItem(
            latex: #"\cos(\theta + \varphi) = \cos(\theta)\cos(\varphi) - \sin(\theta)\sin(\varphi)"#,
            height: 40),
        FormulaItem(
            latex: #"\frac{1}{\left(\sqrt{\phi \sqrt{5}}-\phi\right) e^{\frac25 \pi}} = 1+\frac{e^{-2\pi}} {1 +\frac{e^{-4\pi}} {1+\frac{e^{-6\pi}} {1+\frac{e^{-8\pi}} {1+\cdots} } } }"#,
            height: 80),
        FormulaItem(
            latex: #"\sigma = \sqrt{\frac{1}{N}\sum_{i=1}^N (x_i - \mu)^2}"#,
            height: 60),
        FormulaItem(
            latex: #"\neg(P\land Q) \iff (\neg P)\lor(\neg Q)"#,
            height: 40),
        FormulaItem(
            latex: #"\log_b(x) = \frac{\log_a(x)}{\log_a(b)}"#,
            height: 40),
        FormulaItem(
            latex: #"\lim_{x\to\infty}\left(1 + \frac{k}{x}\right)^x = e^k"#,
            height: 40),
        FormulaItem(
            latex: #"\int_{-\infty}^\infty \! e^{-x^2} dx = \sqrt{\pi}"#,
            height: 40),
        FormulaItem(
            latex: #"\frac 1 n \sum_{i=1}^{n}x_i \geq \sqrt[n]{\prod_{i=1}^{n}x_i}"#,
            height: 60),
        FormulaItem(
            latex: #"f^{(n)}(z_0) = \frac{n!}{2\pi i}\oint_\gamma\frac{f(z)}{(z-z_0)^{n+1}}\,dz"#,
            height: 40),
        FormulaItem(
            latex: #"i\hbar\frac{\partial}{\partial t}\mathbf\Psi(\mathbf{x},t) = -\frac{\hbar}{2m}\nabla^2\mathbf\Psi(\mathbf{x},t) + V(\mathbf{x})\mathbf\Psi(\mathbf{x},t)"#,
            height: 40),
        FormulaItem(
            latex: #"\left(\sum_{k=1}^n a_k b_k \right)^2 \le \left(\sum_{k=1}^n a_k^2\right)\left(\sum_{k=1}^n b_k^2\right)"#,
            height: 60),
        FormulaItem(
            latex: #"{n \brace k} = \frac{1}{k!}\sum_{j=0}^k (-1)^{k-j}\binom{k}{j}(k-j)^n"#,
            height: 60),
        FormulaItem(
            latex: #"f(x) = \int\limits_{-\infty}^\infty\!\hat f(\xi)\,e^{2 \pi i \xi x}\,\mathrm{d}\xi"#,
            height: 60),
        FormulaItem(
            latex: #"\begin{gather}\dot{x} = \sigma(y-x) \\ \dot{y} = \rho x - y - xz \\ \dot{z} = -\beta z + xy \end{gather}"#,
            height: 70),
        FormulaItem(
            latex: #"\vec \bf V_1 \times \vec \bf V_2 =  \begin{vmatrix} \hat \imath &\hat \jmath &\hat k \\ \frac{\partial X}{\partial u} &  \frac{\partial Y}{\partial u} & 0 \\ \frac{\partial X}{\partial v} &  \frac{\partial Y}{\partial v} & 0 \end{vmatrix}"#,
            height: 70),
        FormulaItem(
            latex: #"\begin{eqalign} \nabla \cdot \vec{\bf{E}} & = \frac {\rho} {\varepsilon_0} \\ \nabla \cdot \vec{\bf{B}} & = 0 \\ \nabla \times \vec{\bf{E}} &= - \frac{\partial\vec{\bf{B}}}{\partial t} \\ \nabla \times \vec{\bf{B}} & = \mu_0\vec{\bf{J}} + \mu_0\varepsilon_0 \frac{\partial\vec{\bf{E}}}{\partial t} \end{eqalign}"#,
            height: 140),
        FormulaItem(
            latex: #"\begin{pmatrix} a & b\\ c & d \end{pmatrix} \begin{pmatrix} \alpha & \beta \\ \gamma & \delta \end{pmatrix} = \begin{pmatrix} a\alpha + b\gamma & a\beta + b \delta \\ c\alpha + d\gamma & c\beta + d \delta \end{pmatrix}"#,
            height: 60),
        FormulaItem(
            latex: #"\frak Q(\lambda,\hat{\lambda}) = -\frac{1}{2} \mathbb P(O \mid \lambda ) \sum_s \sum_m \sum_t \gamma_m^{(s)} (t) +\\ \quad \left( \log(2 \pi ) + \log \left| \cal C_m^{(s)} \right| + \left( o_t - \hat{\mu}_m^{(s)} \right) ^T \cal C_m^{(s)-1} \right)"#,
            height: 90),
        FormulaItem(
            latex: #"f(x) = \begin{cases} \frac{e^x}{2} & x \geq 0 \\ 1 & x < 0 \end{cases}"#,
            height: 60),
        FormulaItem(
            latex: #"\color{#ff3333}{c}\color{#9933ff}{o}\color{#ff0080}{l}+\color{#99ff33}{\frac{\color{#ff99ff}{o}}{\color{#990099}{r}}}-\color{#33ffff}{\sqrt[\color{#3399ff}{e}]{\color{#3333ff}{d}}}"#,
            height: 60),
    ]

    static let testFormulae: [FormulaItem] = [
        FormulaItem(latex: #"3+2-5 = 0"#, height: 40, backgroundColor: tintedBackground),
        FormulaItem(latex: #"12+-3 > +14"#, height: 40,
                    backgroundColor: tintedBackground, alignment: .center),
        FormulaItem(latex: #"(-3-5=-8, -6-7=-13)"#, height: 40),
        FormulaItem(latex: #"5\times(-2 \div 1) = -10"#, height: 40,
                    backgroundColor: tintedBackground, alignment: .right,
                    contentInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20)),
        FormulaItem(latex: #"-h - (5xy+2) = z"#, height: 40),
        FormulaItem(latex: #"\frac12x + \frac{3\div4}2y = 25"#, height: 60, mode: .text),
        FormulaItem(latex: #"\frac{x+\frac{12}{5}}{y}+\frac1z = \frac{xz+y+\frac{12}{5}z}{yz}"#,
                    height: 60, backgroundColor: tintedBackground,
                    contentInsets: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)),
        FormulaItem(latex: #"\frac{x+\frac{12}{5}}{y}+\frac1z = \frac{xz+y+\frac{12}{5}z}{yz}"#,
                    height: 60, backgroundColor: tintedBackground, mode: .text),
        FormulaItem(latex: #"\frac{x^{2+3y}}{x^{2+4y}} = x^y \times \frac{z_1^{y+1}}{z_1^{y+1}}"#,
                    height: 90, fontSize: 30, alignment: .center),
        FormulaItem(latex: #"\frac{x^{2+3y}}{x^{2+4y}} = x^y \times \frac{z_1^{y+1}}{z_1^{y+1}}"#,
                    height: 30, fontSize: 10, alignment: .center),
        FormulaItem(latex: #"5+\sqrt{2}+3"#, height: 40),
        FormulaItem(latex: #"\sqrt{\frac{\sqrt{\frac{1}{2}} + 3}{\sqrt5^x}}+\sqrt{3x}+x^{\sqrt2}"#,
                    height: 90),
        FormulaItem(latex: #"\sqrt[3]{24} + 3\sqrt{2}24"#, height: 40),
        FormulaItem(latex: #"\sqrt[x+\frac{3}{4}]{\frac{2}{4}+1}"#, height: 60),
        FormulaItem(latex: #"\sin^2(\theta)=\log_3^2(\pi)"#, height: 60),
        FormulaItem(latex: #"\lim_{x\to\infty}\frac{e^2}{1-x}=\limsup_{\sigma}5"#, height: 60),
        FormulaItem(latex: #"\sum_{n=1}^{\infty}\frac{1+n}{1-n}=\bigcup_{A\in\Im}C\cup B"#,
                    height: 60),
        FormulaItem(latex: #"\sum_{n=1}^{\infty}\frac{1+n}{1-n}=\bigcup_{A\in\Im}C\cup B"#,
                    height: 60, mode: .text),
        FormulaItem(latex: #"\lim_{x\to\infty}\frac{e^2}{1-x}=\limsup_{\sigma}5"#,
                    height: 60, mode: .text),
        FormulaItem(latex: #"\int_{0}^{\infty}e^x \,dx=\oint_0^{\Delta}5\Gamma"#, height: 60),
        FormulaItem(latex: #"\int\int\int^{\infty}\int_0\int^{\infty}_0\int"#, height: 60),
        FormulaItem(latex: #"U_3^2UY_3^2U_3Y^2f_1f^2ff"#, height: 60),
        FormulaItem(latex: #"\notacommand"#, height: 30),
        FormulaItem(latex: #"\sqrt{1}"#, height: 20),
        FormulaItem(latex: #"\sqrt[|]{1}"#, height: 20),
        FormulaItem(latex: #"{n \choose k}"#, height: 60),
        FormulaItem(latex: #"{n \choose k}"#, height: 30, mode: .text),
        FormulaItem(latex: #"\left({n \atop k}\right)"#, height: 40),
        FormulaItem(latex: #"\left({n \atop k}\right)"#, height: 30, mode: .text),
        FormulaItem(latex: #"\underline{xyz}+\overline{abc}"#, height: 30),
        FormulaItem(latex: #"\underline{\frac12}+\overline{\frac34}"#, height: 50),
        FormulaItem(latex: #"\underline{x^\overline{y}_\overline{z}+5}"#, height: 50),
        FormulaItem(latex: #"\int\!\!\!\int_D dx\,dy"#, height: 50),
        FormulaItem(latex: #"\int\int_D dxdy"#, height: 50),
        FormulaItem(latex: #"y\,dx-x\,dy"#, height: 30),
        FormulaItem(latex: #"y dx - x dy"#, height: 30),
        FormulaItem(latex: #"hello\ from \quad the \qquad other\ side"#, height: 30),
        FormulaItem(latex: #"\vec x \; \hat y \; \breve {x^2} \; \tilde x \tilde x^2 x^2 "#,
                    height: 30),
        FormulaItem(latex: #"\hat{xyz} \; \widehat{xyz}\; \vec{2ab}"#, height: 30),
        FormulaItem(latex: #"\hat{\frac12} \; \hat{\sqrt 3}"#, height: 50),
        FormulaItem(
            latex: #"\colorbox{#f0f0e0}{\sqrt{1+\colorbox{#d0c0d0}{\sqrt{1+\colorbox{#a080c0}{\sqrt{1+\colorbox{#7050a0}{\sqrt{1+\colorbox{403060}{\colorbox{#102000}{\sqrt{1+\cdots}}}}}}}}}}}"#,
            height: 80),
        FormulaItem(latex: #"\begin{bmatrix} a & b\\ c & d \\ e & f \\ g &  h \\ i & j \end{bmatrix}"#,
                    height: 120),
        FormulaItem(latex: #"x{\scriptstyle y}z"#, height: 30),
        FormulaItem(
            latex: #"x \mathrm x \mathbf x \mathcal X \mathfrak x \mathsf x \bm x \mathtt x \mathit \Lambda \cal g"#,
            height: 30),
        FormulaItem(latex: #"\mathrm{using\ mathrm}"#, height: 30),
        FormulaItem(latex: #"\text{using text}"#, height: 30),
        FormulaItem(latex: #"\text{Mary has }\$500 + \$200."#, height: 30),
        FormulaItem(
            latex: #"\colorbox{#888888}{\begin{pmatrix}\colorbox{#ff0000}{a} & \colorbox{#00ff00}{b} \\ \colorbox{#00aaff}{c} & \colorbox{#f0f0f0}{d} \end{pmatrix}}"#,
            height: 70),
    ]
}
