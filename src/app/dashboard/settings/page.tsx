"use client";

import { useState, useEffect } from "react";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { useTheme } from "@/components/theme-provider";

export default function SettingsPage() {
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const { theme, setTheme } = useTheme();

  useEffect(() => {
    const supabase = createClient();
    supabase.auth.getUser().then(({ data: { user } }) => {
      if (user) {
        setFullName(user.user_metadata?.full_name || "");
        setEmail(user.email || "");
      }
    });
  }, []);

  const handleSave = async () => {
    setLoading(true);
    setMessage(null);
    const supabase = createClient();
    const { error } = await supabase.auth.updateUser({
      data: { full_name: fullName },
    });
    setMessage(error ? error.message : "Profil mis a jour !");
    setLoading(false);
  };

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold tracking-tight">Parametres</h1>
        <p className="text-muted-foreground">Gerez votre profil et vos preferences.</p>
      </div>

      <div className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle>Profil</CardTitle>
            <CardDescription>Mettez a jour vos informations personnelles.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {message && (
              <div className="rounded-md bg-primary/10 p-3 text-sm">{message}</div>
            )}
            <div className="space-y-2">
              <Label htmlFor="fullName">Nom complet</Label>
              <Input
                id="fullName"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input id="email" value={email} disabled />
            </div>
            <Button onClick={handleSave} disabled={loading}>
              {loading ? "Sauvegarde..." : "Sauvegarder"}
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Apparence</CardTitle>
            <CardDescription>Choisissez votre theme prefere.</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex gap-3">
              {(["light", "dark", "system"] as const).map((t) => (
                <Button
                  key={t}
                  variant={theme === t ? "default" : "outline"}
                  size="sm"
                  onClick={() => setTheme(t)}
                >
                  {t === "light" ? "Clair" : t === "dark" ? "Sombre" : "Systeme"}
                </Button>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
