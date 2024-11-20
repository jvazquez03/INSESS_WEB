// api/config.js

module.exports = (req, res) => {
    // Aquí puedes acceder a las variables de entorno configuradas en Vercel
    const apiKey = process.env.API_KEY;  // Asumiendo que tienes esta variable configurada en Vercel
  
    // Devuelves las variables como un objeto JSON
    res.status(200).json({ apiKey: apiKey });
  };