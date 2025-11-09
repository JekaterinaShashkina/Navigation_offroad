import { Navigate } from "react-router"; 
import { useContext } from "react";
import { AuthContext } from "../context/AuthContext";

export function Protected({ children }) {
    const { user } = useContext(AuthContext); // Võtab AuthContext-ist praeguse kasutaja

    if (!user) {
        // Kui kasutaja ei ole autentitud, suuna sisselogimise lehele
        return <Navigate to="/signin" replace />;
    }

    // Kui kasutaja on autentitud, tagasta kaitstud sisu (lapsed)
    return children;
}