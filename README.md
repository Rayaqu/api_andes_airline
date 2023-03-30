# Andes Airline simulación Check-in
RESTful API desarrollado en **Ruby** y **Ruby on Rails** usando las últimas versiones del software.<br>
Desplegado en [Render](https://render.com/) y probado en [POSTMAN](https://www.postman.com/).

<p align="center">
  <img width="460" height="300" src="https://i.imgur.com/kxxai5o.png">
</p>


## Instrucciones
- Si se desea probar la API en Postman, se requerirá una cuenta gratuita.
- Copiar la siguiente URL para acceder a la API:
`https://andes-airline.onrender.com/flights/ID/passengers`
Reemplazar el ID por el número de `flight_id` deseado.
- Pegar en la barra de direcciones de Postman, seleccionar el método GET y hacer clic en **Send**.
<br>
La respuesta también se muestra en el navegador.<br>
<p align="center">
  <img width="460" height="300" src="https://i.imgur.com/kM7jOvz.png">
</p>

### Notas:
Render tiene algunas limitaciones en el Free Tier.<br>
Tal como se indica en la [documentación](https://render.com/docs/free#free-web-services) de la página web de Render, el sistema se ralentizará después de 15 minutos de inactividad.<br>
Esto podría causar un retraso de hasta 30 segundos para recibir una respuesta de la API.<br>
Pasado los 30 segundos la API funcionará con normalidad.<br>
