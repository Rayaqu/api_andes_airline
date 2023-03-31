# Andes Airline simulación Check-in
RESTful API desarrollado en **Ruby** y **Ruby on Rails** usando las últimas versiones del software.<br>
Desplegado en [Render](https://render.com/) y probado en [POSTMAN](https://www.postman.com/).
<p align="center">
  <img width="460" height="300" src="https://i.imgur.com/kxxai5o.png">
</p>
<br>
URL de Acceso a la API: https://andes-airline.onrender.com/flights/1/passengers

## Características
- Matrices de los dos aviones con los asientos designados
- Todos los pasajeros están distribuídos de acuerdo a su tipo de asiento
- Pasajeros organizados por tarjeta de embarque
- Cada menor de edad se sienta al lado de un acompañante adulto

## Instrucciones
1. Copiar la siguiente dirección para acceder a la API:
`https://andes-airline.onrender.com/flights/ID/passengers`
2. Ir a la URL: https://extendsclass.com/rest-client-online.html
3. Pegar en el campo el URL copiado y seleccionar el método GET.
4. Reemplazar el ID en la dirección por el número de `flight_id` deseado y hacer clic en **Send**.
5. Se mostrará el resultado en el campo de texto **Body**
6. Click en `Format the reponse` para organizar los datos.

La respuesta también se muestra en el navegador.<br>
<p align="center">
  <img width="460" height="300" src="https://i.imgur.com/kM7jOvz.png">
</p>

- Si se desea probar la API en Postman, se requerirá una cuenta gratuita.
- Copiar la siguiente dirección para acceder a la API:
`https://andes-airline.onrender.com/flights/ID/passengers`
- Pegar en la barra de direcciones de Postman y seleccionar el método GET.
- Reemplazar el ID en la dirección por el número de `flight_id` deseado y hacer clic en **Send**.

### Notas:
Render tiene algunas limitaciones en el Free Tier.<br>
Tal como se indica en la [documentación](https://render.com/docs/free#free-web-services) de la página web de Render, el sistema se ralentizará después de 15 minutos de inactividad.<br>
Esto podría causar un retraso de hasta 30 segundos para recibir una respuesta de la API.<br>
Pasado los 30 segundos la API funcionará con normalidad.<br>
