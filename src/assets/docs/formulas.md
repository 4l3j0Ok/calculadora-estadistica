# Fórmulas prácticas de Probabilidad y Estadística

## Índice general

### Parte I — Estadística

1. [Notación básica](#1-notación-básica)
2. [Tabla de frecuencias](#2-tabla-de-frecuencias)
3. [Datos no agrupados](#3-datos-no-agrupados)
4. [Datos agrupados por valor](#4-datos-agrupados-por-valor)
5. [Datos agrupados por intervalos](#5-datos-agrupados-por-intervalos)
6. [Rango](#6-rango)
7. [Varianza](#7-varianza)
8. [Desvío estándar](#8-desvío-estándar)
9. [Coeficiente de variación](#9-coeficiente-de-variación)
10. [Representatividad del promedio](#10-representatividad-del-promedio)
11. [Cuartiles, deciles y percentiles](#11-cuartiles-deciles-y-percentiles)
12. [Tablas auxiliares](#12-tablas-auxiliares)
13. [Resumen rápido](#resumen-rápido)

### Parte II — Probabilidad

1. [Notación básica de probabilidad](#1-notación-básica-de-probabilidad)
2. [Reglas básicas](#2-reglas-básicas)
3. [Regla de Laplace](#3-regla-de-laplace)
4. [Complemento](#4-complemento)
5. [Unión: “A o B”](#5-unión-a-o-b)
6. [Regiones de un diagrama de Venn](#6-regiones-de-un-diagrama-de-venn)
7. [Probabilidad condicional](#7-probabilidad-condicional)
8. [Regla del producto: “A y B”](#8-regla-del-producto-a-y-b)
9. [Independencia](#9-independencia)
10. [Extracciones con y sin reposición](#10-extracciones-con-y-sin-reposición)
11. [Probabilidad total](#11-probabilidad-total)
12. [Teorema de Bayes](#12-teorema-de-bayes)
13. [Tablas de contingencia](#13-tablas-de-contingencia)
14. [Conteo para varios elementos](#14-conteo-para-varios-elementos)
15. [Distribución de probabilidad de una variable aleatoria discreta](#15-distribución-de-probabilidad-de-una-variable-aleatoria-discreta)
16. [Traducción rápida del lenguaje cotidiano](#16-traducción-rápida-del-lenguaje-cotidiano)
17. [Procedimiento de resolución recomendado](#17-procedimiento-de-resolución-recomendado)
18. [Resumen ultrarrápido de probabilidad](#resumen-ultrarrápido-de-probabilidad)

---

## Parte I — Estadística

### 1. Notación básica

| Símbolo | Significado |
|---|---|
| \(x_i\) | Valor observado |
| \(x_i^\ast\) | Marca de clase |
| \(f_i\) | Frecuencia absoluta |
| \(f_{r_i}\) | Frecuencia relativa |
| \(F_i\) | Frecuencia absoluta acumulada |
| \(f_i\%\) | Frecuencia porcentual |
| \(F_i\%\) | Frecuencia porcentual acumulada |
| \(n\) | Tamaño de la muestra |
| \(N\) | Tamaño de la población |
| \(\bar{x}\) | Media muestral |
| \(\mu\) | Media poblacional |
| \(s^2\) | Varianza muestral |
| \(\sigma^2\) | Varianza poblacional |
| \(s\) | Desvío estándar muestral |
| \(\sigma\) | Desvío estándar poblacional |
| \(CV\) | Coeficiente de variación |
| \(L_i\) | Límite inferior del intervalo |
| \(L_s\) | Límite superior del intervalo |
| \(c\) | Amplitud del intervalo |

#### Total de datos

Muestra:

\[
n=\sum f_i
\]

Población:

\[
N=\sum f_i
\]

---

### 2. Tabla de frecuencias

#### Frecuencia relativa

\[
f_{r_i}=\frac{f_i}{n}
\]

#### Frecuencia porcentual

\[
f_i\%=f_{r_i}\cdot100
\]

#### Frecuencia absoluta acumulada

\[
F_i=\sum_{j=1}^{i}f_j
\]

#### Frecuencia porcentual acumulada

\[
F_i\%=\sum_{j=1}^{i}f_j\%
\]

#### Tabla base

| \(x_i\) | \(f_i\) | \(f_{r_i}\) | \(F_i\) | \(f_i\%\) | \(F_i\%\) |
|---:|---:|---:|---:|---:|---:|

---

### 3. Datos no agrupados

Ejemplo:

```text
3, 6, 4, 6, 2, 5
```

#### Media muestral

\[
\bar{x}=\frac{\sum x_i}{n}
\]

#### Media poblacional

\[
\mu=\frac{\sum x_i}{N}
\]

#### Mediana

Primero se ordenan los datos.

Cantidad impar:

\[
Me=x_{\left(\frac{n+1}{2}\right)}
\]

Cantidad par:

\[
Me=
\frac{x_{\left(\frac{n}{2}\right)}
+x_{\left(\frac{n}{2}+1\right)}}{2}
\]

#### Moda

La moda es el valor con mayor frecuencia.

\[
Mo=x_i \quad \text{tal que } f_i=\max(f)
\]

Puede ser:

- unimodal;
- bimodal;
- multimodal;
- sin moda.

#### Varianza muestral

\[
s^2=\frac{\sum(x_i-\bar{x})^2}{n-1}
\]

#### Varianza poblacional

\[
\sigma^2=\frac{\sum(x_i-\mu)^2}{N}
\]

---

### 4. Datos agrupados por valor

Ejemplo:

| \(x_i\) | \(f_i\) |
|---:|---:|
| 700 | 5 |
| 800 | 5 |
| 1200 | 4 |

#### Media

\[
\bar{x}=
\frac{\sum x_i f_i}{\sum f_i}
\]

#### Mediana

Calcular:

\[
\frac{n}{2}
\]

Luego buscar esa posición en la frecuencia acumulada.

Si las dos posiciones centrales pertenecen a valores distintos:

\[
Me=
\frac{x_{\frac{n}{2}}+x_{\frac{n}{2}+1}}{2}
\]

#### Moda

El valor \(x_i\) cuya frecuencia \(f_i\) sea la mayor.

\[
Mo=x_i \quad \text{tal que } f_i=\max(f)
\]

#### Varianza muestral

\[
s^2=
\frac{\sum f_i(x_i-\bar{x})^2}{n-1}
\]

#### Varianza poblacional

\[
\sigma^2=
\frac{\sum f_i(x_i-\mu)^2}{N}
\]

---

### 5. Datos agrupados por intervalos

Ejemplo:

| Intervalo | \(f_i\) |
|---|---:|
| \([0,20)\) | 15 |
| \([20,40)\) | 25 |
| \([40,60)\) | 60 |

#### Marca de clase

\[
x_i^\ast=\frac{L_i+L_s}{2}
\]

#### Amplitud

\[
c=L_s-L_i
\]

#### Media aproximada

\[
\bar{x}\approx
\frac{\sum x_i^\ast f_i}{\sum f_i}
\]

El resultado es aproximado porque todos los valores del intervalo se representan mediante la marca de clase.

#### Mediana aproximada

\[
Me=L_i+
\left(
\frac{\frac{n}{2}-F_{\text{anterior}}}{f_m}
\right)c
\]

Donde:

- \(L_i\): límite inferior de la clase mediana;
- \(F_{\text{anterior}}\): frecuencia acumulada anterior;
- \(f_m\): frecuencia de la clase mediana;
- \(c\): amplitud.

#### Moda aproximada

\[
Mo=L_i+
\frac{f_m-f_{\text{anterior}}}
{(f_m-f_{\text{anterior}})
+(f_m-f_{\text{siguiente}})}
\cdot c
\]

Donde:

- \(L_i\): límite inferior de la clase modal;
- \(f_m\): frecuencia de la clase modal;
- \(f_{\text{anterior}}\): frecuencia anterior;
- \(f_{\text{siguiente}}\): frecuencia siguiente;
- \(c\): amplitud.

#### Varianza muestral aproximada

\[
s^2\approx
\frac{\sum f_i(x_i^\ast-\bar{x})^2}{n-1}
\]

#### Varianza poblacional aproximada

\[
\sigma^2\approx
\frac{\sum f_i(x_i^\ast-\mu)^2}{N}
\]

---

### 6. Rango

#### Datos no agrupados o agrupados por valor

\[
R=x_{\max}-x_{\min}
\]

#### Datos agrupados por intervalos

\[
R=
L_{\text{superior final}}
-
L_{\text{inferior inicial}}
\]

---

### 7. Varianza

La varianza mide cuánto se dispersan los datos respecto de la media.

#### Resumen

| Tipo de datos | Muestra | Población |
|---|---|---|
| No agrupados | \(\displaystyle s^2=\frac{\sum(x_i-\bar{x})^2}{n-1}\) | \(\displaystyle \sigma^2=\frac{\sum(x_i-\mu)^2}{N}\) |
| Agrupados por valor | \(\displaystyle s^2=\frac{\sum f_i(x_i-\bar{x})^2}{n-1}\) | \(\displaystyle \sigma^2=\frac{\sum f_i(x_i-\mu)^2}{N}\) |
| Agrupados por intervalos | \(\displaystyle s^2\approx\frac{\sum f_i(x_i^\ast-\bar{x})^2}{n-1}\) | \(\displaystyle \sigma^2\approx\frac{\sum f_i(x_i^\ast-\mu)^2}{N}\) |

---

### 8. Desvío estándar

#### Muestra

\[
s=\sqrt{s^2}
\]

#### Población

\[
\sigma=\sqrt{\sigma^2}
\]

El desvío estándar indica cuánto se separan los datos respecto de la media y se expresa en la misma unidad que los datos.

---

### 9. Coeficiente de variación

#### Muestra

\[
CV=\frac{s}{|\bar{x}|}\cdot100
\]

#### Población

\[
CV=\frac{\sigma}{|\mu|}\cdot100
\]

#### Interpretación orientativa

| CV | Interpretación |
|---:|---|
| Menor que 10% | Muy homogéneo |
| Entre 10% y 20% | Homogéneo |
| Entre 20% y 30% | Dispersión moderada |
| Mayor que 30% | Heterogéneo |

Estos límites son orientativos y pueden variar según la materia o el contexto.

---

### 10. Representatividad del promedio

Regla práctica:

- CV bajo: los datos están cerca de la media y el promedio suele ser representativo.
- CV alto: los datos están dispersos y el promedio puede no ser representativo.
- Los valores extremos también pueden deformar la media.
- Una distribución asimétrica puede hacer que la media sea poco representativa.
- Cuando la media no representa bien al conjunto, conviene revisar la mediana.

El CV no es el único criterio, pero es una herramienta útil para evaluar la representatividad.

---

### 11. Cuartiles, deciles y percentiles

#### Cuartil con intervalos

\[
Q_k=L_i+
\left(
\frac{\frac{kn}{4}-F_{\text{anterior}}}{f_i}
\right)c
\]

#### Decil con intervalos

\[
D_k=L_i+
\left(
\frac{\frac{kn}{10}-F_{\text{anterior}}}{f_i}
\right)c
\]

#### Percentil con intervalos

\[
P_k=L_i+
\left(
\frac{\frac{kn}{100}-F_{\text{anterior}}}{f_i}
\right)c
\]

#### Interpretaciones útiles

- “Superada por el 10%” corresponde a \(P_{90}\).
- “El 25% queda por debajo” corresponde a \(Q_1\).
- “El 50% queda por debajo” corresponde a la mediana o \(P_{50}\).
- “El 75% queda por debajo” corresponde a \(Q_3\).

---

### 12. Tablas auxiliares

#### Frecuencias

```text
xi | fi | fr | Fi | f% | F%
```

#### Dispersión sin frecuencias

```text
xi | xi - media | (xi - media)²
```

#### Dispersión con frecuencias

```text
xi | fi | xi - media | (xi - media)² | fi(xi - media)²
```

#### Dispersión con intervalos

```text
Intervalo | marca de clase | fi | xi - media | (xi - media)² | fi(xi - media)²
```

---

### Resumen rápido

#### No agrupados

\[
\bar{x}=\frac{\sum x_i}{n}
\]

\[
s^2=\frac{\sum(x_i-\bar{x})^2}{n-1}
\]

#### Agrupados por valor

\[
\bar{x}=\frac{\sum x_if_i}{\sum f_i}
\]

\[
s^2=\frac{\sum f_i(x_i-\bar{x})^2}{n-1}
\]

#### Agrupados por intervalos

\[
x_i^\ast=\frac{L_i+L_s}{2}
\]

\[
\bar{x}\approx\frac{\sum x_i^\ast f_i}{\sum f_i}
\]

\[
s^2\approx
\frac{\sum f_i(x_i^\ast-\bar{x})^2}{n-1}
\]

---

## Parte II — Probabilidad

### 1. Notación básica de probabilidad

| Símbolo | Significado |
|---|---|
| \(S\) o \(\Omega\) | Espacio muestral: todos los resultados posibles |
| \(A,B,C\) | Sucesos o eventos |
| \(\varnothing\) | Suceso imposible |
| \(A^c\), \(\overline A\) o \(\text{No }A\) | Complemento de \(A\) |
| \(A\cup B\) | Unión: ocurre \(A\), \(B\) o ambos |
| \(A\cap B\) | Intersección: ocurren \(A\) y \(B\) |
| \(A-B\) | Ocurre \(A\), pero no \(B\) |
| \(P(A)\) | Probabilidad de que ocurra \(A\) |
| \(P(A\mid B)\) | Probabilidad de \(A\) sabiendo que ocurrió \(B\) |
| \(n(A)\) | Cantidad de elementos o casos del suceso \(A\) |

#### Ayuda de memoria: símbolos y palabras

| El enunciado dice… | Se traduce como… | Región de Venn |
|---|---|---|
| “A o B”, “alguno de los dos” | \(A\cup B\) | Todo lo que esté dentro de cualquiera de los círculos |
| “A y B”, “ambos” | \(A\cap B\) | La zona compartida |
| “solo A” | \(A-B=A\cap B^c\) | Parte exclusiva de \(A\) |
| “ninguno” | \((A\cup B)^c\) | Fuera de ambos círculos |
| “no A” | \(A^c\) | Todo lo que queda fuera de \(A\) |
| “si ocurrió B” / “de los que son B” | \(P(A\mid B)\) | El nuevo total es solamente \(B\) |

> **Memoria principal:** en probabilidad, **“o” suele sumar**, **“y” suele multiplicar o buscar una intersección**, **“no” resta a 1** y **“si sabemos que…” cambia el denominador**.

---

### 2. Reglas básicas

Toda probabilidad cumple:

\[
0\le P(A)\le1
\]

\[
P(S)=1
\]

\[
P(\varnothing)=0
\]

Si se trabaja con porcentajes:

\[
100\%=1
\]

Conversión:

\[
P(A)=\frac{\text{porcentaje}}{100}
\]

\[
\text{Porcentaje}=P(A)\cdot100
\]

---

### 3. Regla de Laplace

Se usa cuando todos los resultados elementales son **equiprobables**.

\[
P(A)=\frac{n(A)}{n(S)}
=\frac{\text{casos favorables}}{\text{casos posibles}}
\]

#### Ayuda de memoria

- **Abajo:** todo lo que puede ocurrir.
- **Arriba:** solo lo que cumple lo pedido.
- \(n(A)\) cuenta casos; \(P(A)\) divide esos casos por el total.
- No se divide nuevamente si ya se está trabajando con probabilidades dadas.

---

### 4. Complemento

\[
P(A^c)=1-P(A)
\]

También:

\[
P(A)+P(A^c)=1
\]

#### Frases típicas

- “No ocurra \(A\)” → \(A^c\).
- “Ninguno de los dos” → \((A\cup B)^c\).
- “Al menos uno” suele ser más fácil por complemento:

\[
P(\text{al menos uno})=1-P(\text{ninguno})
\]

Para \(n\) intentos independientes con probabilidad \(p\) de éxito:

\[
P(\text{al menos un éxito})=1-(1-p)^n
\]

> **Memoria:** “al menos uno” = **uno menos la probabilidad de cero**.

---

### 5. Unión: “A o B”

#### Sucesos compatibles o no excluyentes

Pueden ocurrir simultáneamente, por lo que existe intersección:

\[
P(A\cup B)=P(A)+P(B)-P(A\cap B)
\]

Se resta la intersección porque fue contada dos veces.

#### Sucesos incompatibles o mutuamente excluyentes

No pueden ocurrir al mismo tiempo:

\[
A\cap B=\varnothing
\]

\[
P(A\cap B)=0
\]

Entonces:

\[
P(A\cup B)=P(A)+P(B)
\]

> **Memoria Venn:** si los círculos se pisan, restá el centro. Si están separados, solo sumá.

---

### 6. Regiones de un diagrama de Venn

#### Solo A

\[
P(A\text{ solo})=P(A)-P(A\cap B)
\]

#### Solo B

\[
P(B\text{ solo})=P(B)-P(A\cap B)
\]

#### Ninguno

\[
P(\text{ninguno})=1-P(A\cup B)
\]

#### Exactamente uno de los dos

\[
P(\text{exactamente uno})
=P(A\text{ solo})+P(B\text{ solo})
\]

Equivalente:

\[
P(\text{exactamente uno})
=P(A)+P(B)-2P(A\cap B)
\]

#### Cómo completar un Venn de dos conjuntos

1. Colocar primero \(A\cap B\) en el centro.
2. Calcular las zonas exclusivas restando el centro.
3. Sumar las tres regiones internas para obtener \(A\cup B\).
4. Restar la unión al total para obtener “ninguno”.

> **Memoria:** siempre empezar **desde el centro hacia afuera**.

---

### 7. Probabilidad condicional

\[
P(A\mid B)=\frac{P(A\cap B)}{P(B)}
\qquad P(B)>0
\]

Con cantidades:

\[
P(A\mid B)=\frac{n(A\cap B)}{n(B)}
\]

#### Ayuda de memoria

En \(P(A\mid B)\):

- lo que está **después de la barra** es la condición;
- la condición se convierte en el **nuevo universo**;
- por eso el denominador es \(P(B)\) o \(n(B)\), no el total general.

Frases típicas:

- “Si es remoto, ¿qué probabilidad hay de que sea frontend?”
- “De quienes sufrieron el problema, ¿qué proporción eran desarrolladores?”
- “Sabiendo que ocurrió \(B\), calcular \(A\)”.

Todas se leen como \(P(A\mid B)\).

---

### 8. Regla del producto: “A y B”

Despejando la fórmula condicional:

\[
P(A\cap B)=P(B)\cdot P(A\mid B)
\]

También:

\[
P(A\cap B)=P(A)\cdot P(B\mid A)
\]

#### Extracciones sucesivas

\[
P(A_1\cap A_2\cap\cdots\cap A_n)
=P(A_1)P(A_2\mid A_1)\cdots P(A_n\mid A_1\cap\cdots\cap A_{n-1})
\]

> **Memoria:** en un árbol, para avanzar por una misma rama se **multiplica**; para reunir ramas alternativas se **suma**.

---

### 9. Independencia

Dos sucesos son independientes cuando saber que ocurrió uno no cambia la probabilidad del otro.

Formas equivalentes:

\[
P(A\mid B)=P(A)
\]

\[
P(B\mid A)=P(B)
\]

\[
P(A\cap B)=P(A)P(B)
\]

Para demostrar independencia, alcanza con verificar una de estas igualdades.

#### No confundir

- **Incompatibles:** no pueden ocurrir juntos, \(P(A\cap B)=0\).
- **Independientes:** sí pueden ocurrir juntos, pero uno no afecta al otro.

Salvo casos de probabilidad cero, dos sucesos incompatibles **no** son independientes.

> **Memoria:** incompatibles habla de **coincidir**; independientes habla de **influir**.

---

### 10. Extracciones con y sin reposición

#### Con reposición

El elemento vuelve al conjunto:

- el total no cambia;
- las probabilidades suelen mantenerse;
- las extracciones suelen ser independientes.

Ejemplo general:

\[
P(A\text{ y luego }B)=P(A)P(B)
\]

#### Sin reposición

El elemento no vuelve:

- el total disminuye;
- puede cambiar también la cantidad de casos favorables;
- las extracciones son dependientes.

Ejemplo general:

\[
P(A\text{ y luego }B)=P(A)P(B\mid A)
\]

> **Memoria:** sin reposición, en la segunda fracción el denominador baja en 1.

---

### 11. Probabilidad total

Se usa cuando un suceso \(A\) puede ocurrir a través de varios grupos o caminos \(B_1,B_2,\ldots,B_n\), que forman una partición del espacio muestral.

\[
P(A)=\sum_{i=1}^{n}P(B_i)P(A\mid B_i)
\]

Desarrollada:

\[
P(A)=P(B_1)P(A\mid B_1)+P(B_2)P(A\mid B_2)+\cdots+P(B_n)P(A\mid B_n)
\]

#### Ayuda de memoria

- Cada producto representa una rama completa del árbol.
- Se multiplica dentro de cada rama.
- Se suman todas las ramas que terminan en \(A\).

> **Memoria:** probabilidad total = **sumar todos los caminos que llevan al mismo resultado**.

---

### 12. Teorema de Bayes

Permite invertir una condición:

\[
P(B_j\mid A)=
\frac{P(B_j)P(A\mid B_j)}{P(A)}
\]

Usando probabilidad total en el denominador:

\[
P(B_j\mid A)=
\frac{P(B_j)P(A\mid B_j)}
{\sum_{i=1}^{n}P(B_i)P(A\mid B_i)}
\]

Para dos grupos:

\[
P(B_1\mid A)=
\frac{P(B_1)P(A\mid B_1)}
{P(B_1)P(A\mid B_1)+P(B_2)P(A\mid B_2)}
\]

#### Ayuda de memoria

- Numerador: el camino específico que interesa.
- Denominador: todos los caminos que producen la evidencia observada.
- Bayes suele aparecer con expresiones como “sabiendo que dio positivo”, “sabiendo que ocurrió la mejora” o “dado que hubo una falla”.

---

### 13. Tablas de contingencia

Para dos características \(A\) y \(B\):

|  | \(B\) | \(B^c\) | Total |
|---|---:|---:|---:|
| \(A\) | \(A\cap B\) | \(A\cap B^c\) | \(A\) |
| \(A^c\) | \(A^c\cap B\) | \(A^c\cap B^c\) | \(A^c\) |
| Total | \(B\) | \(B^c\) | \(S\) |

Con cantidades:

\[
P(A\cap B)=\frac{n(A\cap B)}{n(S)}
\]

\[
P(A\mid B)=\frac{n(A\cap B)}{n(B)}
\]

#### Ayuda de memoria

- Si preguntan por toda la población, dividir por el total general.
- Si dicen “de los que…”, dividir por el total de esa fila o columna.
- Una celda interna suele representar una intersección.

---

### 14. Conteo para varios elementos

#### Principio multiplicativo

Si una decisión tiene \(m\) opciones y otra tiene \(n\), la cantidad de resultados posibles es:

\[
m\cdot n
\]

Para varias etapas:

\[
n(S)=n_1n_2\cdots n_k
\]

#### Factorial

\[
n!=n(n-1)(n-2)\cdots2\cdot1
\]

\[
0!=1
\]

#### Permutaciones de \(n\) elementos

Se usan todos y el orden importa:

\[
P_n=n!
\]

#### Variaciones sin repetición

Se eligen \(r\) elementos de \(n\) y el orden importa:

\[
V_{n,r}=\frac{n!}{(n-r)!}
\]

#### Combinaciones

Se eligen \(r\) elementos de \(n\) y el orden no importa:

\[
\binom nr=\frac{n!}{r!(n-r)!}
\]

> **Memoria:** si cambiar el orden crea un resultado distinto, el orden importa. Si el grupo sigue siendo el mismo, usar combinaciones.

---

### 15. Distribución de probabilidad de una variable aleatoria discreta

Una distribución es válida si:

\[
0\le P(X=x_i)\le1
\]

para cada valor, y:

\[
\sum_i P(X=x_i)=1
\]

Tabla base:

| \(x_i\) | \(P(X=x_i)\) | \(x_iP(X=x_i)\) | \(x_i^2P(X=x_i)\) |
|---:|---:|---:|---:|

#### Esperanza matemática o valor esperado

\[
E(X)=\mu_X=\sum_i x_iP(X=x_i)
\]

Interpretación: valor promedio esperado a largo plazo; no tiene que ser un resultado posible de un único experimento.

#### Segundo momento

\[
E(X^2)=\sum_i x_i^2P(X=x_i)
\]

#### Varianza

Forma directa:

\[
\operatorname{Var}(X)=\sigma_X^2
=\sum_i (x_i-\mu_X)^2P(X=x_i)
\]

Forma abreviada:

\[
\operatorname{Var}(X)=E(X^2)-[E(X)]^2
\]

#### Desvío estándar

\[
\sigma_X=\sqrt{\operatorname{Var}(X)}
\]

#### Coeficiente de variación

\[
CV=\frac{\sigma_X}{|E(X)|}\cdot100
\]

#### Ayuda de memoria para la tabla

1. Verificar que las probabilidades sumen 1.
2. Multiplicar \(x_i\) por su probabilidad y sumar para obtener la esperanza.
3. Para la varianza rápida, sumar \(x_i^2P(x_i)\) y restar \([E(X)]^2\).
4. Sacar raíz para obtener el desvío.
5. Dividir el desvío por la esperanza y multiplicar por 100 para obtener el CV.

---

### 16. Traducción rápida del lenguaje cotidiano

| Expresión | Traducción matemática |
|---|---|
| exactamente \(k\) | \(X=k\) |
| más de \(k\) | \(X>k\) |
| menos de \(k\) | \(X<k\) |
| como máximo \(k\) | \(X\le k\) |
| a lo sumo \(k\) | \(X\le k\) |
| hasta \(k\) | \(X\le k\) |
| como mínimo \(k\) | \(X\ge k\) |
| por lo menos \(k\) | \(X\ge k\) |
| al menos \(k\) | \(X\ge k\) |
| entre \(a\) y \(b\), inclusive | \(a\le X\le b\) |

Para una distribución discreta, se suman las probabilidades de todos los valores que cumplen la condición:

\[
P(X\ge k)=\sum_{x_i\ge k}P(X=x_i)
\]

---

### 17. Procedimiento de resolución recomendado

1. Definir claramente los sucesos con letras.
2. Dibujar un diagrama de Venn cuando haya dos conjuntos o características.
3. Traducir las palabras clave: “o”, “y”, “solo”, “ninguno”, “si…”.
4. Colocar primero la intersección en el Venn.
5. Decidir cuál es el denominador correcto: total general o grupo condicionado.
6. Elegir la fórmula recién después de organizar los datos.
7. Verificar que el resultado esté entre 0 y 1, o entre 0% y 100%.

---

## Resumen ultrarrápido de probabilidad

\[
P(A)=\frac{n(A)}{n(S)}
\]

\[
P(A^c)=1-P(A)
\]

\[
P(A\cup B)=P(A)+P(B)-P(A\cap B)
\]

\[
P(A\mid B)=\frac{P(A\cap B)}{P(B)}
\]

\[
P(A\cap B)=P(B)P(A\mid B)
\]

Si son independientes:

\[
P(A\cap B)=P(A)P(B)
\]

\[
P(A)=\sum_iP(B_i)P(A\mid B_i)
\]

\[
P(B_j\mid A)=\frac{P(B_j)P(A\mid B_j)}{P(A)}
\]

\[
E(X)=\sum_i x_iP(X=x_i)
\]

\[
\operatorname{Var}(X)=E(X^2)-[E(X)]^2
\]
