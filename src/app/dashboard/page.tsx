import { createClient } from "@/lib/supabase/server";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { BarChart3, Users, Zap, TrendingUp } from "lucide-react";

export default async function DashboardPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  const name = user?.user_metadata?.full_name || user?.email?.split("@")[0] || "Utilisateur";

  const stats = [
    { label: "Utilisateurs", value: "0", icon: Users, change: "+0%" },
    { label: "Revenus", value: "0 €", icon: TrendingUp, change: "+0%" },
    { label: "Actions", value: "0", icon: Zap, change: "+0%" },
    { label: "Taux conversion", value: "0%", icon: BarChart3, change: "+0%" },
  ];

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold tracking-tight">Bonjour, {name}</h1>
        <p className="text-muted-foreground">Voici un apercu de votre activite.</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => {
          const Icon = stat.icon;
          return (
            <Card key={stat.label}>
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium">{stat.label}</CardTitle>
                <Icon className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stat.value}</div>
                <p className="text-xs text-muted-foreground">{stat.change} depuis le mois dernier</p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      <div className="mt-8 grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Activite recente</CardTitle>
            <CardDescription>Vos dernieres actions</CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-muted-foreground">Aucune activite pour le moment.</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle>Guide de demarrage</CardTitle>
            <CardDescription>Premiers pas avec votre espace</CardDescription>
          </CardHeader>
          <CardContent>
            <ul className="space-y-2 text-sm">
              <li className="flex items-center gap-2">
                <div className="h-2 w-2 rounded-full bg-primary" />
                Completez votre profil dans les parametres
              </li>
              <li className="flex items-center gap-2">
                <div className="h-2 w-2 rounded-full bg-muted" />
                Explorez les fonctionnalites disponibles
              </li>
              <li className="flex items-center gap-2">
                <div className="h-2 w-2 rounded-full bg-muted" />
                Passez a un plan Pro pour debloquer tout
              </li>
            </ul>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
