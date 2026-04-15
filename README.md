# Offroad Nav

Offroad Nav is an off-road navigation and competition system that includes a Flutter-based mobile application and a React/Vite web client.

The application uses Firebase (Authentication, Firestore, Realtime Database) to provide user authentication, route management, group functionality, and real-time tracking.


## Quick start (Flutter)

```bash
flutter pub get
flutter run
```

## Environment setup

Before running the mobile application, create a .env file in the project root:

```GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here```

Without this file, the Android build will fail because the API key is injected during build time.


## Quick start (Web)
```bash
cd web_app
npm install

npm run dev
```
## Dokumentation
Full project documentation is available in: 

`docs/PROJECT_DOCUMENTATION.md` 

It includes:
* system overview, functional requirements, and business logic;
* architecture diagrams, ER schema, and project structure;
* technical documentation, CI/CD recommendations, and security considerations.

