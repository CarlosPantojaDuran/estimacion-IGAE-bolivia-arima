********************************************************************************
/*
		Diplomado en Métodos Cuantitativos para el Análisis Económico
		Análisis de la Tasa de Crecimiento del IGAE de Bolivia
		Docente: Sergio Bobka
		input: sheet("01.02")
		output: modelos ARIMA

*/

// Limpiar base de datos
clear all

global sd 1

if $sd == 1{ // C. Pantoja (Macbook - ARU)
	global in 	"/Users/usuario1/Documents/5. Macroeconometria/_IN"
	global out  "/Users/usuario1/Documents/5. Macroeconometria/_OUT"
}

// 00. Inicio
* Abrir la base de datos
import excel using "$in\IGAEV.xlsx", firstrow sheet("IGAE") clear

drop H G F I
rename IGAEV tigae


********************************************************************************
* FASE I: IDENTIFICACION
********************************************************************************

******************************************

* Generamos la variable tiempo con periodicidad mensual a partir de marzo de 1992
generate t = tm(2008m1) + _n -1
format %tm t //damos formato de año y mes a la variable t
* Declaramos la serie de tiempo
tsset t

********************************************************************************
* TASA CRECIMIENTO ANUAL DEL IGAE: TIGAE
********************************************************************************

sum tigae // la tasa de crecimiento anual del IGAE general es 3,66%.
tsline tigae, yline(`r(mean)') title("Tasa de Crecimiento del IGAE de Bolivia Ene 2008 - Sep 2023") note(Fuente: INE)

* Creamos la variable temporal: TENDENCIA
reg tigae t
predict xb
rename xb tendencia
la var tendencia "Tendencia del TIGAE"

tsline tigae tendencia

*********************************
// I.1.1 Análisis estacionariedad de la serie TIGAE
// TEST DE DICKEY FULLER
* Como se le quita la tendencia con la tasa de crecimiento no corresponde utilizar el test con tendencia
// Test de Dickey Fuller, sin embargo siguiendo la metodología realizamos el ejercicio, con 12 lags.
dfuller tigae, drift regress lag(12)
* El signo del estadístico t es negativo lo cual es bueno porque indica que la serie no explota
* El coeficiente de Drift es positivo pero no significativo
* p-value > 0.05 y z(t) es menor al valor crítico y por tanto no se RHo, así que existe raíz unitaria y la serie no es estacionaria, sin embargo, debido a que la constante no es significativa, se realiza la prueba sin la misma.

dfuller tigae, noconstant regress lag(12)
* El signo del estadístico t es negativo lo cual es bueno porque indica que la serie no explota
* z(t) es mayor al valor crítico para 10 y 5% y por tanto podría RHo en cuyo caso  existiría estacionariedad, sin embargo al 1% la serie no es estacionaria.

// TEST DE PHILLIP PERRON
pperron tigae, lags(12) regress
* Hay estacionriedad para 10 y 5% pero no para 1%.

// TEST KPSS
kpss tigae, qs auto notrend
* El estadístico es mayor a los valores críticos por tanto se RHo de estacionariedad.
* Como resultado de las tres pruebas y en especial de la tercera se suguiere realizar la primera diferencia.

*********************************
// I.1.2 Análisis autocorrelación de la serie TIGAE
* Correlograma, ACF, PACF
corrgram tigae // se observa una caída gradual en ACF y un PACF con probable AR(2)
* Autocorrelación Total
ac tigae, name (acplot, replace) lags (24)
* se observan una caida gradual de los rezagos

* Autocorrelación Parcial
pac tigae, name (pacplot, replace) lags (24)
graph combine acplot pacplot
* La combinación del comportamiento de ACF y PACF muestran un probable AR2 pero el tercer rezago de PACF apenas pasa la banda.

varsoc tigae // sugiere el uso de 3 rezagos con los criterios de información con LR y SBIC y con los métodos de información FPE, AIC y HQIC se sugiere el uso de 4 rezagos.

******************************************
// ANÁLISIS DE LA ESTACIONALIDAD

* Detectar estacionalidad
separate tigae, by(year) veryshortlabel
line tigae2008-tigae2023 month, xtitle("")

* Método 1
gen d=month(dofm(t))

tab d, gen(d)

reg tigae d1-d12, nocons
predict tigae_estacional, residuals

tsline tigae tigae_estacional // el problema es que se complica el análisis de la variable en niveles.
*************************************************************************
* Método 1.1: complementar aplicando medias móviles
tssmooth ma mm6t= tigae_estacional, window(3 1 3)
tssmooth ma mm12t= tigae_estacional, window(6 1 6)
tssmooth ma mm24t= tigae_estacional, window(12 1 12)
tsline tigae tigae_estacional mm6t mm12t mm24t, title("Método de Medias Móviles") legend(pos (6) size(vsmall))
*************************************************************************
* Método 1.2: Suavización por Efectos estacionales de HOLT-WINTERS-MULTIPLICATIVO***
* Similar al de census x11
* tssmooth shwinters shw1 = tigae, per(12) forecast(24)
*************************************************************************
* Método 1.3: complementar aplicando Hodrick Prescott
tsfilter hp ciclo_hpt = tigae_estacional, trend(tend_hpt)

tsline tigae_estacional tend_hpt, legend(pos(6))
* Es una suavización exagerada, prácticamente no reconoce el COVID.

* Método 1.3: complementar aplicando Baxter - King
tsfilter bk ciclo_bkt= tigae_estacional, trend(tend_bkt)
tsfilter cf ciclo_cft= tigae_estacional, trend(tend_cft)
tsline tigae tigae_estacional tend_hpt tend_bkt tend_cft, title("Filtros HP, BK y CF") legend(pos(6) size(vsmall))

* Si aplico las suavizaciones directamente a la serie
tsfilter hp ciclo_hp2= tigae, trend(tend_hp2)
tsfilter bk ciclo_bk2= tigae, trend(tend_bk2)
tsfilter cf ciclo_cf2= tigae, trend(tend_cf2)

tsline tigae tend_hp2 tend_bk2 tend_cf2, legend(pos(6) size(vsmall))

********************************************************************************
* TASA CRECIMIENTO ANUAL DEL IGAE EN PRIMERA DIFERENCIA: DTIGAE
********************************************************************************
gen dtigae = D.tigae

sum dtigae // la tasa de crecimiento anual del IGAE en primera diferencia es -6,6%.
tsline dtigae, yline(`r(mean)') title("Tasa de Crecimiento del IGAE de Bolivia Ene 2008 - Sep 2023") note(Fuente: INE)

*********************************
// I.1.1 Análisis estacionariedad de la serie TIGAE
// TEST DE DICKEY FULLER
dfuller dtigae, drift regress lag(12)
* El signo del estadístico t es negativo lo cual es bueno porque indica que la serie no explota
* El coeficiente de Drift es negativo pero no significativo
* p-value < 0.05 y z(t) es mayor al valor crítico y por tanto se RHo, así que existe raíz unitaria y la serie no es estacionaria, sin embargo, debido a que la constante no es significativa, se realiza la prueba sin la misma.

dfuller dtigae, noconstant regress lag(12)
* El signo del estadístico t es negativo lo cual es bueno porque indica que la serie no explota
* z(t) es mayor a todos los valores críticos, por tanto se RHo en cuyo caso  existiría estacionariedad.

// TEST DE PHILLIP PERRON
* Con constante
pperron dtigae, lags(12) regress
* Hay estacionariedad para 10, 5 y 1%.

// TEST KPSS
kpss dtigae, qs auto notrend
* El estadístico es menor a los valores críticos por tanto no se RHo de estacionariedad.
* Como resultado de las tres pruebas y en especial de la tercera se afirma que existe estacionariedad en la serie TIGAE en su primera diferencia.

*********************************
// I.1.2 Análisis autocorrelación de la serie DTIGAE
* Correlograma, ACF, PACF
corrgram dtigae // se observa una caída gradual en ACF y un PACF con probable AR(2)
* Autocorrelación Total
ac dtigae, name (acplot, replace) lags (24)
* se observan una caida gradual de los rezagos

* Autocorrelación Parcial
pac dtigae, name (pacplot, replace) lags (24)
graph combine acplot pacplot
* La combinación del comportamiento de ACF y PACF muestran que las caídas en ambos gráficos no son graduales, lo que podría significar un proceso ARMA (2,2). Sin embargo en ACF se observan entre los meses 10-15 3 rezagos que superan las bandas y parecieran tener un comportamiento sistemático.

varsoc dtigae // sugiere el uso de 2 rezagos con todos los criterios de información.
arimasoc dtigae // sugiere un AR2
*************************************
// 02. FASE: ESTIMACIÓN Y PRUEBAS
// 02.1 SELECCIÓN Y ESTIMACIÓN
* 1. Analizando los gráficos ACF y PACF así como el comando varsoc, podría existir el modelo:
arima tigae, arima(2,1,2)
* Todos los coeficientes son significativos con excepción de la constante.
* 2. Usando arimasoc, se debería elegir un MA2 y AR2
arima tigae, arima(0,1,2)
arima tigae, arima(2,1,0)

// 02.2 DIAGNÓSTICO
* Modelo1:
predict res_arima212, resid

* Modelo2:
predict res_arima012, resid
predict res_arima210, resid

* NORMALIDAD DE LOS RESIDUOS
* Modelo 1
qnorm res_arima212 // gráficamente los residuos no tienen distribución normal.
swilk res_arima212 // el test de parámetros tampoco muestra distribución normal.

* Modelo2:
qnorm res_arima012 // gráficamente los residuos no tienen distribución normal.
swilk res_arima012 // el test de parámetros tampoco muestra distribución normal.

qnorm res_arima210 // gráficamente los residuos no tienen distribución normal.
swilk res_arima210 // el test de parámetros tampoco muestra distribución normal.

* AUTOCORRELACIÓN
* Modelo1:
ac res_arima212
pac res_arima212
// Existe autocorrelación de los residuos.
* Modelo2:
ac res_arima012
pac res_arima012
* Existe autocorrelación de los residuos.
ac res_arima210
pac res_arima210
* Empeora la autocorrelación de los residuos.

* TEST DE RUIDO BLANCO
* Modelo1:
// White Noise: Prueba de ruido blanco "Portmanteau test"
* Ho: ruido blanco; >0.05
* H1: no hay ruido blanco; <0.05
wntestq res_arima212
* El resultado es que no hay ruido blanco
wntestb res_arima212 // el gráfico muestra que no existe ruido blanco
sum res_arima212
tsline res_arima212, yline(`r(mean)')

* Modelo2:
wntestq res_arima012
* El resultado es que existe ruido blanco
wntestb res_arima012 // el gráfico muestra que no existe ruido blanco
sum res_arima012
tsline res_arima012, yline(`r(mean)')

wntestq res_arima210
* El resultado es que existe ruido blanco
wntestb res_arima210 // el gráfico muestra que no existe ruido blanco
sum res_arima210
tsline res_arima210, yline(`r(mean)')

* En ambos casos no se cumplen las pruebas post estimación, por lo que se procede a utilizar otros paquetes econométricos para completar el análisis de la serie.


********************************************************************************
* FASE I: PRONOSTICO I
********************************************************************************
gen new_date = ym(year, month)
tsset new_date
drop if new_date==.

tsappend, add(24) // añadimos dos años
arima tigae, arima(2,1,0) sarima(1,0,0,12)
estimates store modelo210_100
forecast create modelo210_100
forecast estimates modelo210_100, names(pron)
forecast identity tigae = pron + L.tigae
forecast solve, prefix(f_) begin(744) end(788)

predict fvar, mse
generate superior=f_tigae + 1.96*sqrt(fvar)
generate inferior=f_tigae - 1.96*sqrt(fvar)

replace superior = f_tigae if new_date <744
replace inferior = f_tigae if new_date <744

*******************************************
***COMPARACION DEL ORIGINAL Y PRONOSTICO***
*******************************************

tsline tigae superior inferior f_tigae
graph export "$out/pronostico.png",replace
