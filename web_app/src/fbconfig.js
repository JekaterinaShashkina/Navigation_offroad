import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "AIzaSyBHg8yCZ-2JUM32JndVTeAWGFhZXzrSvnQ",
  authDomain: "react-ff62a.firebaseapp.com",
  projectId: "react-ff62a",
  storageBucket: "react-ff62a.firebasestorage.app",
  messagingSenderId: "273719108763",
  appId: "1:273719108763:web:242a38ee24049884d6523e",
  measurementId: "G-33K0QK2ZMT"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

export { app, db };