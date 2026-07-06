# Fórmulas prácticas de Estadística

## Índice

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

---

## 1. Notación básica

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

### Total de datos

Muestra:

\[
n=\sum f_i
\]

Población:

\[
N=\sum f_i
\]

---

## 2. Tabla de frecuencias

### Frecuencia relativa

\[
f_{r_i}=\frac{f_i}{n}
\]

### Frecuencia porcentual

\[
f_i\%=f_{r_i}\cdot100
\]

### Frecuencia absoluta acumulada

\[
F_i=\sum_{j=1}^{i}f_j
\]

### Frecuencia porcentual acumulada

\[
F_i\%=\sum_{j=1}^{i}f_j\%
\]

### Tabla base

| \(x_i\) | \(f_i\) | \(f_{r_i}\) | \(F_i\) | \(f_i\%\) | \(F_i\%\) |
|---:|---:|---:|---:|---:|---:|

---

## 3. Datos no agrupados

Ejemplo:

```text
3, 6, 4, 6, 2, 5
```

### Media muestral

\[
\bar{x}=\frac{\sum x_i}{n}
\]

### Media poblacional

\[
\mu=\frac{\sum x_i}{N}
\]

### Mediana

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

### Moda

La moda es el valor con mayor frecuencia.

\[
Mo=x_i \quad \text{tal que } f_i=\max(f)
\]

Puede ser:

- unimodal;
- bimodal;
- multimodal;
- sin moda.

### Varianza muestral

\[
s^2=\frac{\sum(x_i-\bar{x})^2}{n-1}
\]

### Varianza poblacional

\[
\sigma^2=\frac{\sum(x_i-\mu)^2}{N}
\]

---

## 4. Datos agrupados por valor

Ejemplo:

| \(x_i\) | \(f_i\) |
|---:|---:|
| 700 | 5 |
| 800 | 5 |
| 1200 | 4 |

### Media

\[
\bar{x}=
\frac{\sum x_i f_i}{\sum f_i}
\]

### Mediana

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

### Moda

El valor \(x_i\) cuya frecuencia \(f_i\) sea la mayor.

\[
Mo=x_i \quad \text{tal que } f_i=\max(f)
\]

### Varianza muestral

\[
s^2=
\frac{\sum f_i(x_i-\bar{x})^2}{n-1}
\]

### Varianza poblacional

\[
\sigma^2=
\frac{\sum f_i(x_i-\mu)^2}{N}
\]

---

## 5. Datos agrupados por intervalos

Ejemplo:

| Intervalo | \(f_i\) |
|---|---:|
| \([0,20)\) | 15 |
| \([20,40)\) | 25 |
| \([40,60)\) | 60 |

### Marca de clase

\[
x_i^\ast=\frac{L_i+L_s}{2}
\]

### Amplitud

\[
c=L_s-L_i
\]

### Media aproximada

\[
\bar{x}\approx
\frac{\sum x_i^\ast f_i}{\sum f_i}
\]

El resultado es aproximado porque todos los valores del intervalo se representan mediante la marca de clase.

### Mediana aproximada

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

### Moda aproximada

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

### Varianza muestral aproximada

\[
s^2\approx
\frac{\sum f_i(x_i^\ast-\bar{x})^2}{n-1}
\]

### Varianza poblacional aproximada

\[
\sigma^2\approx
\frac{\sum f_i(x_i^\ast-\mu)^2}{N}
\]

---

## 6. Rango

### Datos no agrupados o agrupados por valor

\[
R=x_{\max}-x_{\min}
\]

### Datos agrupados por intervalos

\[
R=
L_{\text{superior final}}
-
L_{\text{inferior inicial}}
\]

---

## 7. Varianza

La varianza mide cuánto se dispersan los datos respecto de la media.

### Resumen

| Tipo de datos | Muestra | Población |
|---|---|---|
| No agrupados | \(\displaystyle s^2=\frac{\sum(x_i-\bar{x})^2}{n-1}\) | \(\displaystyle \sigma^2=\frac{\sum(x_i-\mu)^2}{N}\) |
| Agrupados por valor | \(\displaystyle s^2=\frac{\sum f_i(x_i-\bar{x})^2}{n-1}\) | \(\displaystyle \sigma^2=\frac{\sum f_i(x_i-\mu)^2}{N}\) |
| Agrupados por intervalos | \(\displaystyle s^2\approx\frac{\sum f_i(x_i^\ast-\bar{x})^2}{n-1}\) | \(\displaystyle \sigma^2\approx\frac{\sum f_i(x_i^\ast-\mu)^2}{N}\) |

---

## 8. Desvío estándar

### Muestra

\[
s=\sqrt{s^2}
\]

### Población

\[
\sigma=\sqrt{\sigma^2}
\]

El desvío estándar indica cuánto se separan los datos respecto de la media y se expresa en la misma unidad que los datos.

---

## 9. Coeficiente de variación

### Muestra

\[
CV=\frac{s}{|\bar{x}|}\cdot100
\]

### Población

\[
CV=\frac{\sigma}{|\mu|}\cdot100
\]

### Interpretación orientativa

| CV | Interpretación |
|---:|---|
| Menor que 10% | Muy homogéneo |
| Entre 10% y 20% | Homogéneo |
| Entre 20% y 30% | Dispersión moderada |
| Mayor que 30% | Heterogéneo |

Estos límites son orientativos y pueden variar según la materia o el contexto.

---

## 10. Representatividad del promedio

Regla práctica:

- CV bajo: los datos están cerca de la media y el promedio suele ser representativo.
- CV alto: los datos están dispersos y el promedio puede no ser representativo.
- Los valores extremos también pueden deformar la media.
- Una distribución asimétrica puede hacer que la media sea poco representativa.
- Cuando la media no representa bien al conjunto, conviene revisar la mediana.

El CV no es el único criterio, pero es una herramienta útil para evaluar la representatividad.

---

## 11. Cuartiles, deciles y percentiles

### Cuartil con intervalos

\[
Q_k=L_i+
\left(
\frac{\frac{kn}{4}-F_{\text{anterior}}}{f_i}
\right)c
\]

### Decil con intervalos

\[
D_k=L_i+
\left(
\frac{\frac{kn}{10}-F_{\text{anterior}}}{f_i}
\right)c
\]

### Percentil con intervalos

\[
P_k=L_i+
\left(
\frac{\frac{kn}{100}-F_{\text{anterior}}}{f_i}
\right)c
\]

### Interpretaciones útiles

- “Superada por el 10%” corresponde a \(P_{90}\).
- “El 25% queda por debajo” corresponde a \(Q_1\).
- “El 50% queda por debajo” corresponde a la mediana o \(P_{50}\).
- “El 75% queda por debajo” corresponde a \(Q_3\).

---

## 12. Tablas auxiliares

### Frecuencias

```text
xi | fi | fr | Fi | f% | F%
```

### Dispersión sin frecuencias

```text
xi | xi - media | (xi - media)²
```

### Dispersión con frecuencias

```text
xi | fi | xi - media | (xi - media)² | fi(xi - media)²
```

### Dispersión con intervalos

```text
Intervalo | marca de clase | fi | xi - media | (xi - media)² | fi(xi - media)²
```

---

## Resumen rápido

### No agrupados

\[
\bar{x}=\frac{\sum x_i}{n}
\]

\[
s^2=\frac{\sum(x_i-\bar{x})^2}{n-1}
\]

### Agrupados por valor

\[
\bar{x}=\frac{\sum x_if_i}{\sum f_i}
\]

\[
s^2=\frac{\sum f_i(x_i-\bar{x})^2}{n-1}
\]

### Agrupados por intervalos

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
