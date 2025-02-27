const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const axios = require('axios');
const admin = require('firebase-admin');
const { db, auth } = require('./firebaseConfig'); // Importar la configuración de Firebase


//autenticacion

// Configuración del servidor express
const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: '*',
        methods: ['GET', 'POST'],
    },
});
app.use(cors());
app.use(express.json());


// Nuevo endpoint para listar colecciones
app.get('/collections', async (req, res) => {
    try {
        const collectionsSnapshot = await db.listCollections();
        const collectionNames = collectionsSnapshot.map(collection => collection.id);
        res.json({ collections: collectionNames });
    } catch (error) {
        console.error('Error al listar colecciones:', error);
        res.status(500).send('Error al listar colecciones');
    }
});
// Endpoint para listar documentos de la colección "mensajes"
app.get('/messages', async (req, res) => {
    const Mensajes = db.collection("message");
    const snapshot = await Mensajes.get();

    const list = snapshot.docs.map((doc) => {
        const data = doc.data();
        // Convertir el timestamp de Firestore a un objeto Date
        const timestamp = data.timestamp;
        const timestampDate = timestamp ? new Date(timestamp._seconds * 1000) : null; // Convertir segundos a milisegundos
        return { id: doc.id, ...data, timestamp: timestampDate };
    });

    res.send(list);
    console.log(list);
});

app.post('/register', async (req, res) => {
    const { email, password } = req.body;
    try {
        const userRecord = await auth.createUser({
            email: email,
            password: password,
            emailVerified: false,
            disabled: false
        });
        // Cambia a userRecord.uid
        res.status(201).send({ uid: userRecord.uid });
    } catch (error) {
        console.error('Error al crear el usuario:', error); // Agrega un log para ver el error
        res.status(400).send({ error: error.message });
    }
});
app.post('/login1', async (req, res) => {
    const { email, password } = req.body;
    try {
        const user = await auth.getUserByEmail(email);
        // Aquí deberías verificar la contraseña (esto es solo un ejemplo)
        // En producción, usa Firebase Authentication para autenticar
        res.status(200).json({ uid: user.uid , upass: user.passwordHash});
      } catch (error) {
        res.status(401).json({ error: 'Usuario no encontrado' });
      }
});
app.post("/login", async (req, res) => {
    const { email, password } = req.body;
  
    try {
      // 🔹 Petición a Firebase Authentication REST API para validar email y password
      const response = await axios.post(
        `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyCcZaNvJShR6G0UNkrmN3s2PZ9duK8nvC0`,
        {
          email,
          password,
          returnSecureToken: true,
        }
      );
  
      const { localId } = response.data; // UID del usuario en Firebase
  
      // 🔹 Genera un token JWT personalizado con Firebase Admin SDK
      const customToken = await admin.auth().createCustomToken(localId);
  
      res.status(200).json({ uid: localId, token: customToken });
    } catch (error) {
      res.status(401).json({ error: "Correo o contraseña incorrectos"+error });
    }
  });
  
  app.post("/logout", async (req, res) => {
    const { uid } = req.body; // Recibe el UID del usuario
  
    try {
      // 🔹 Revoca todos los tokens del usuario (forzará el cierre de sesión en todos los dispositivos)
      await admin.auth().revokeRefreshTokens(uid);
  
      res.status(200).json({ message: "Sesión cerrada correctamente" });
    } catch (error) {
      res.status(500).json({ error: "Error al cerrar sesión" });
    }
  });
  
  


// WebSocket: Socket.IO
io.on('connection', (socket) => {
    console.log('Usuario conectado');

    socket.on('sendMessage', async (data) => {
        const newMessage = {
            username: data.usuario,
            message: data.mensaje,
            timestamp: admin.firestore.FieldValue.serverTimestamp() // Usar el timestamp del servidor
        };
        await db.collection('message').add(newMessage); // Guardar el mensaje en Firestore
        io.emit('receiveMessage', newMessage); // Enviar el mensaje a todos los clientes conectados
    });

    socket.on('disconnect', () => {
        console.log('Usuario desconectado');
    });
});

// Iniciar servidor por el puerto
server.listen(3000, () => {
    console.log('Servidor corriendo en http://localhost:3000');
});
