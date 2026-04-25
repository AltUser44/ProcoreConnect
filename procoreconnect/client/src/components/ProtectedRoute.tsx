import { Navigate, useLocation } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import { LoadingState } from "./LoadingState";

interface ProtectedRouteProps {
  children: React.ReactNode;
}

export function ProtectedRoute({ children }: ProtectedRouteProps) {
  const { status } = useAuth();
  const location = useLocation();

  if (status === "loading") {
    return (
      <div className="mx-auto max-w-7xl px-6 py-10">
        <LoadingState label="Checking session..." />
      </div>
    );
  }

  if (status === "unauthenticated") {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />;
  }

  return <>{children}</>;
}
