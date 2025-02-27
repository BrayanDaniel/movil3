// firebaseConfig.js
const admin = require('firebase-admin');
const { initializeApp } = require('firebase/app');
const { getAuth } = require('firebase/auth');
const serviceAccount = require('./chattiemporeal-e454e-firebase-adminsdk-fbsvc-efc0548f32.json');

// Inicializar Firebase Admin SDK
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});


  
  const firebaseApp = initializeApp(firebaseConfig);
  const auth1 = getAuth(firebaseApp);
  const auth=admin.auth();
const db = admin.firestore(); // Inicializa Firestore


// Exporta las instancias de Firestore y Auth
module.exports = { db, auth };