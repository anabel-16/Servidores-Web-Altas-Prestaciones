from locust import HttpUser, TaskSet, task, between

class P5_anaiperez(TaskSet):
    @task
    def load_index(self):
        self.client.get("/index.php", verify=False)

class P5_usuarios(HttpUser):
    tasks = [P5_anaiperez]
    wait_time = between(1, 5)



class P5_navAvanzadaCMS(TaskSet):
    
    def on_start(self):
        """Se ejecuta al iniciar el usuario virtual: Autenticación obligatoria"""
        usuario_id = random.randint(1, 1000)
        datos_login = {
            "username": f"user_anai_{usuario_id}",
            "password": "password_seguro_p5"
        }
        #Autenticación en el CMS
        self.client.post("/login.php", data=datos_login, verify=False, name="CMS: Login")

    def buscar_contenido(self):
        """Ejecución de consultas de búsqueda en la BD"""
        terminos = ["cine", "pelicula", "director", "estreno", "reseña"]
        query = random.choice(terminos)
        self.client.get(f"/buscar.php?q={query}", verify=False, name="CMS: Buscador BD")

    def ver_paginas_contenido(self):
        """Navegación por páginas y carga de múltiples tipos de contenido"""
        id_post = random.randint(1, 50)
        self.client.get(f"/contenido.php?id={id_post}", verify=False, name="CMS: Ver Pagina Contenido")

    def interactuar_con_bd(self):
        """Interacción con BD (Insertar comentarios o publicaciones)"""
        id_post = random.randint(1, 50)
        datos_comentario = {
            "post_id": id_post,
            "comentario": "Aportación de prueba automatizada avanzada para evaluación de carga en la BD.",
            "autor": "Locust_Worker_Anai"
        }
        self.client.post("/insertar_comentario.php", data=datos_comentario, verify=False, name="BD: Insertar Comentario")

    def carga_contenido_pesado(self):
        """Carga de múltiples tipos de contenido masivo (ej. Archivos/Multimedia)"""
        self.client.get("/upload.php", verify=False, name="CMS: Carga Multimedia Pesada") 

class P5_Usuarios_Avanzados(HttpUser):
   
    tasks = [P5_navAvanzadaCMS]
    wait_time = between(2, 5)
    
