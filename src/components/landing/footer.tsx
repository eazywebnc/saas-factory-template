import { saasConfig } from "../../../saas.config";

export function Footer() {
  return (
    <footer className="border-t py-12">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <div className="flex flex-col items-center justify-between gap-4 sm:flex-row">
          <p className="text-sm text-muted-foreground">
            &copy; {new Date().getFullYear()} {saasConfig.name}. Tous droits reserves.
          </p>
          <div className="flex gap-6">
            <a href="#" className="text-sm text-muted-foreground hover:text-foreground">
              Mentions legales
            </a>
            <a href="#" className="text-sm text-muted-foreground hover:text-foreground">
              Confidentialite
            </a>
            <a href="#" className="text-sm text-muted-foreground hover:text-foreground">
              Contact
            </a>
          </div>
        </div>
        <p className="mt-4 text-center text-xs text-muted-foreground">
          Propulse par <a href="https://eazyweb.nc" className="font-medium hover:underline">EazyWebNC</a>
        </p>
      </div>
    </footer>
  );
}
