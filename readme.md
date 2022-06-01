# MeLi DataWarehousing Challenge
This project allows the user to run a series of given queries in a dummy database. In order to achieve that, on the one hand it creates a virtual environment containing the jupyter notebook later used to perform all the queries, and installs all the required dependencies, as well as an ipython kernel for the notebook. On the other hand it builds a docker image which, when started, creates and populates the dummy database. Finally, the required queries can be run through the jupyter notebook.

## How to use this project

### build docker image

```console
$ docker build -t meli_test .
```

### start docker image

```console
$ sudo docker run -p 5432:5432 meli_test
```

### create and activate venv
```console
$ python3 -m venv .venv

$ source .venv/bin/activate
```

### install requirements.txt
```console
$ pip install -r requirements.txt
```

### install a kernell inside the environment, to run in the notebook

```console
$ ipython kernel install --user --name=.venv
```


## Referecies
- https://hub.docker.com/_/postgres/

-----------
# Nivel 1

## Query 1

### *'¿Cuál es la hora del día en que se realizan más búsquedas en MercadoLibre?'*

```console
SELECT extract(hour from timestamp) as hour
FROM dataset_meli
WHERE event_name = 'SEARCH'
GROUP BY hour
ORDER BY count(*) desc
LIMIT 1;
```

## Query 2

### *'¿Cuál fue el experimento que tuvo más participantes dentro del dataset?'*

Para responder esta pregunta debemos introducirnos dentro del los diferentes Map<> que tenemos en la base de datos, dentro de la columna 'experiments', en formato texto.

Para esto se siguieron dos estrategias diferentes:

### 1) Parsear el texto 

```console
SELECT SPLIT_PART(experiments_, '=', 1) as splitted_exp, count(*) as count
FROM (  SELECT unnest(string_to_array(experiments_, ',')) as experiments_
        FROM (  SELECT REPLACE((
                SELECT REPLACE((
                SELECT REPLACE(experiments,' , ',',')
                ),'}','')
                ),'{','') as experiments_ FROM dataset_meli) table_) table_
GROUP BY splitted_exp
ORDER BY count DESC
LIMIT 1;
```

### 2) Nueva columna formato JSON y buscar los valores por clave.

Esta solucion suele ser más performante por varios motivos, el principal tiene que ver con que se parsea el texto una sola vez cuando se carga el dataset y posteriormente las busquedas se realizan por clave o valor del JSON. 

**Crear nueva columna JSON**

```console
ALTER TABLE dataset_meli
ADD COLUMN experiments_json json;

UPDATE 
   dataset_meli
SET 
   experiments_json =  CAST( REPLACE((
       SELECT REPLACE((
       SELECT REPLACE((
       SELECT REPLACE(experiments, ', ','", "')), '{','{"')), '}','"}')), '=','" : "') AS JSON);
```

**Query para obtener el resultado**
```console
WITH experiments AS (
        SELECT json_object_keys(experiments_json) experiment 
        FROM dataset_meli)
SELECT experiment, COUNT(*) as count 
FROM experiments 
GROUP BY experiment
ORDER BY count desc
LIMIT 1;
```

# Nivel 2
*'Pensando en la posibilidad de que sea accedido por miles y miles de usuarios…'*

### ***c. ¿Qué estrategias utilizarías para asegurar que el acceso a los recursos de dicho motor sean justos y equitativos entre los distintos usuarios?***

Por empezar analizaría que cumpla los lineamientos básicos de una base relacional, en cuanto a la normalización de las tablas para evitar la redundancia (lo justo y necesario para no afectar la performance), la optimización y actualización de estadísticas y planes de ejecución, analizar cuál sería el índice de búsqueda más eficiente, o dado que los usuarios no van a efectuar transacciones sobre esta base, se puede implementar una ejecución concurrente de las consultas.


### ***d. ¿Qué controles podríamos implementar para garantizar la auditoria y el control de acceso en dicho motor de consulta?***

Al tratarse de un DWH, los usuarios que consultan esta información solo requieren permisos de lectura, este sería un mecanismo de control fundamental.

Respecto a la auditoría, es importante que los datos del DWH sean consistentes con los datos de origen, sería una buena práctica implementar un script que analice discrepancias con los datos de origen, registros repetidos o la ausencia de algún dato. Pero también podríamos auditar la disponibilidad del servicio, los tiempos de respuesta, las vulnerabilidades o las distintas querys que se realizan a la base.

Dado que estos datos pueden consultarse desde distintas fuentes, por ejemplo, haciendo querys desde el mismo SGBD, aplicaciones externas o internas que consuman esta información a través de microservicios, entre otras, es importante implementar un control de acceso, en este caso creo que basado en roles sería una buena opción, donde podamos ejecutar seguimiento de las acciones de los usuarios y limitar las consultas que estos usuarios pueden realizar. Relacionando esto con el párrafo anterior, también es fundamental efectuar auditorias sobre los usuarios habilitados para mantenerlos actualizados.


### ***e. ¿Qué estrategias o modificaciones le harías al guardado de la tabla en tu storage para optimizar las consultas sobre la misma?***

En principio, sería oportuno hacer un ETL inicial que nos permita hacer una carga limpia de la base de datos, eliminando anomalías (por ejemplo líneas vacías) y dando el formato correcto para qué la carga en el DWH se ejecute sin problemas. 

Por otro lado, se puede analizar si es necesario normalizar las tablas para qué las consultas por experimentos sean más eficientes. Con un diagrama de entidad relación podemos analizar una arquitectura dónde, por ejemplo, los experimentos y sus variantes sean guardados en una tabla relacionada mediante una foreign key, y en la tabla actual se almacenen los usuarios y los experimentos a los que fueron expuestos. 

Si tenemos grupos bien definidos de usuarios que consultan este DWH podemos crear data marts para los distintos tipos de usuarios, segmentando las consultas y logrando mayor performance.

Se podría pensar entonces en un sistema donde tengamos en primer lugar un storage de raw ingestion, donde a partir de un proceso de transformación se almacene en tablas normalizadas con las transformaciones, filtros y limpieza adecuada. Finalmente, generar la información agregada en formato de cubos OLAP, Data Mining o incluso Forecasting que el negocio requiera a nivel BI.


### ***f. ¿Qué estrategias de ahorro de costos podemos implementar para evitar el crecimiento indefinido de este storage?***
- Disponibilizar los resultados de los experimentos que ya finalizaron de manera agregada y no los datos crudos, de modo que se pueda almacenar la data cruda en algún formato que consuma menos espacio en disco o incluso eliminarla si el negocio considera que los datos agregados son los suficientemente representativos para el posterior análisis de BI.

-  Mientras más normalicemos las tablas vamos a obtener un menor almacenamiento (ya que tendremos menos redundancia) pero a costa de hacer más lentas las consultas.

### Referencias
- https://aws.amazon.com/data-warehouse/?nc1=h_ls
- https://satoricyber.com/data-protect-guide/data-lake-and-data-warehouse-security/
- Apuntes de la materia Sistemas de Datos, Licenciatura en Sistemas, FCE 2021. 




