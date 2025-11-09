import { SignIn } from './routes/Signin'
import { SignUp } from './routes/Signup'
import { Home } from './routes/Home'
import { createBrowserRouter, RouterProvider } from 'react-router'
import { AuthProvider } from './context/AuthProvider';
import { Protected } from './routes/Protected';


function App() {
  const router = createBrowserRouter([
    {
      path: '/',
      element: (
        <Protected>
          <Home />
        </Protected>
      ),
    },
    {
      path: '/home',
      element: (
        <Protected>
          <Home />
        </Protected>
      ),
    },
    {
      path: '/signin',
      element: <SignIn />,
    },
    {
      path: '/signup',
      element: <SignUp />,
    },
  ]);

  return (
    <AuthProvider>
      <RouterProvider router={router} />
    </AuthProvider>
  );
}

export default App;