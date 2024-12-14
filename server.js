const express = require('express'); 
const bodyParser = require('body-parser');
const path = require('path');
const fs = require('fs');
const { exec } = require('child_process');
const session = require('express-session'); // Importar express-session
const mongoose = require('mongoose'); 
const os = require('os'); 
const json2csv = require('json2csv').parse;  // Asegúrate de instalar json2csv

const app = express();
app.use(express.static(path.join(__dirname, 'public')));
 
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Configurar express-session
app.use(session({
    secret: 'tu_secreto_aqui', // Cambia esto por una cadena secreta
    resave: false,
    saveUninitialized: true,
    cookie: { secure: false } // Cambiar a true si usas HTTPS
}));

const mongoURI = "mongodb+srv://joanvazquez:28112002@cluster0.nipyo.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0";
mongoose.connect(mongoURI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    serverSelectionTimeoutMS: 50000 // Aumenta el tiempo de espera a 50 segundos
  })
  .then(() => {
    console.log('Conexión a MongoDB exitosa');
  })
  .catch(err => {
    console.error('Error al conectar a MongoDB:', err);
  });


// Esquema de usuario
const User = require('./models/User');
const Form = require('./models/Forms');
const Block = require("./models/Block");
const Question = require("./models/Question");
 
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public/docs', 'login.html')); // Sirve el formulario de registro
});

// Ruta para servir la página de inicio de sesión (login.html)
app.get('/login', (req, res) => {
    res.sendFile(path.join(__dirname, 'public/docs', 'login.html')); // Sirve el formulario de login
});
 
app.get('/forms', (req, res) => {
    res.sendFile(path.join(__dirname, 'public/docs', 'forms.html')); // Sirve el formulario de login
});

// Ruta para registrar un nuevo usuario
app.post('/register', async (req, res) => {
    const { username, password } = req.body;

    try {
        // Verificar si el nombre de usuario ya existe
        const existingUser = await User.findOne({ username });
        if (existingUser) {
            // Si el usuario ya existe, enviamos un mensaje de error
            return res.status(400).send('El nombre de usuario ya está en uso');
        }

        // Crear un nuevo usuario si el nombre no existe
        const newUser = new User({ username, password });
        await newUser.save();
        
        console.log(`Usuario registrado: ${username}`);
        
        // Redirigir al login después de registrarse
        res.redirect('/login');
    } catch (err) {
        console.error('Error al registrar el usuario:', err);
        res.status(500).send('Error al registrar el usuario');
    }
});



app.post('/login', async (req, res) => {
    const { username, password } = req.body;

    try {
        // Buscar el usuario en la base de datos
        const user = await User.findOne({ username });

        if (!user) {
            return res.status(400).json({ success: false, message: 'Usuario no encontrado' });
        }

        // Comparar contraseña (sin hash)
        if (user.password !== password) {
            return res.status(400).json({ success: false, message: 'Contraseña incorrecta' });
        }
 
        res.json({ success: true, userId: user._id });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Error en el servidor' });
    }
});

app.get('/get-user/:userId', async (req, res) => {
    const { userId } = req.params;

    try {
        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        res.json({
            user, 
        });
    } catch (error) {
        console.error("Error al obtener los datos del usuario:", error);
        res.status(500).json({ message: 'Error en el servidor' });
    }
});


app.post('/user/create-form', async (req, res) => {
    try {
        const { title, author } = req.body;

        if (!title || !author) {
            return res.status(400).json({ message: 'Falta el título o el autor del formulario.' });
        }
 
        const newForm = new Form({
            title,
            createdAt: new Date(),
            author: author, // Asignar el ID del usuario como autor 
        });

        const savedForm = await newForm.save();
        res.status(201).json(savedForm);
    } catch (error) {
        console.error('Error al crear el formulario:', error);
        res.status(500).json({ message: 'Error al crear el formulario.' });
    }
});


app.delete('/user/delete-form', async (req, res) => {
    const { formId, userId } = req.body;

    try {
        // Paso 1: Eliminar el formulario de la colección 'forms'
        const form = await Form.findByIdAndDelete(formId);
        
        if (!form) {
            return res.status(404).json({ error: 'Formulario no encontrado' });
        }

        // Paso 2: Remover el ID del formulario del array 'forms' del usuario
        const user = await User.findByIdAndUpdate(
            userId,
            { $pull: { forms: formId } },
            { new: true }
        );

        if (!user) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        res.status(200).json({ message: 'Formulario eliminado exitosamente', user });
    } catch (error) {
        console.error("Error al eliminar el formulario:", error);
        res.status(500).json({ error: 'Error al eliminar el formulario' });
    }
});



app.post('/add-form-to-user', async (req, res) => {
    try {
        const { userId } = req.query;
        const { formId } = req.body;

        if (!userId || !formId) {
            return res.status(400).json({ message: 'Faltan el userId o el formId.' });
        }

        // Busca el usuario y agrega el ID del formulario al array 'forms'
        const updatedUser = await User.findByIdAndUpdate(
            userId,
            { $push: { forms: formId } },
            { new: true }
        );

        if (!updatedUser) {
            return res.status(404).json({ message: 'Usuario no encontrado.' });
        }

        res.status(200).json({ message: 'Formulario agregado al usuario correctamente.', user: updatedUser });
    } catch (error) {
        console.error('Error al agregar el formulario al usuario:', error);
        res.status(500).json({ message: 'Error al agregar el formulario al usuario.' });
    }
});


// Ruta para obtener la información del usuario logueado
app.get('/profile', async (req, res) => {
    const userId = req.query.userId;

    if (userId) {
        try {
            const user = await User.findById(userId); // Busca al usuario en la base de datos

            if (user) {
                res.json({user});
            } else {
                res.status(404).json({ message: "Usuario no encontrado" });
            }
        } catch (error) {
            res.status(500).json({ message: "Error al obtener el usuario", error });
        }
    } else {
        res.status(400).json({ message: "ID de usuario no proporcionado" });
    }
});



app.get('/get-form', async (req, res) => {
    const { id } = req.query;

    try {
        const form = await Form.findById(id);
        
        if (!form) {
            return res.status(404).json({ error: 'Formulario no encontrado' });
        }

        res.status(200).json({ form });
    } catch (error) {
        console.error("Error al obtener los detalles del formulario:", error);
        res.status(500).json({ error: 'Error al obtener los detalles del formulario' });
    }
});

app.get('/get-question/:id', async (req, res) => {
    const { id } = req.params; // Obtener el ID de la pregunta desde los parámetros

    try {
        // Buscar la pregunta en la base de datos
        const question = await Question.findById(id);

        if (!question) {
            return res.status(404).json({ error: 'Pregunta no encontrada' });
        }

        // Enviar la pregunta como respuesta
        res.json(question);
    } catch (error) {
        console.error('Error al obtener la pregunta:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});


app.post("/create-block", async (req, res) => {
    const { title, formId } = req.body;

    try {
        // Crear un nuevo bloque
        const newBlock = new Block({
            title,
            questions: [],
        });

        // Guardar el bloque en la base de datos
        await newBlock.save();

        // Obtener el formId del formulario que se está editando
        const formId = req.body.formId;

        if (formId) {
            // Buscar el formulario en la base de datos usando formId
            const form = await Form.findById(formId);
            if (!form) {
                return res.status(404).send("Formulario no encontrado");
            }
 
            // Añadir el ID del bloque al formulario
            console.log(form.bloques)
            form.bloques.push(newBlock._id);

            // Guardar el formulario actualizado
            await form.save();
        }

        // Responder con el bloque recién creado
        res.status(201).json(newBlock);
    } catch (error) {
        console.error("Error al crear el bloque:", error);
        res.status(500).send("Error al crear el bloque");
    }
});

 
app.post('/add-question', async (req, res) => {
    try {
        const { block, data } = req.body;
        
        // Validar los datos recibidos si es necesario
        if (!data.pregunta || !data.tipusPregunta) {
            return res.status(400).json({ message: 'Pregunta y tipo de pregunta son obligatorios' });
        }

        // Crear una nueva instancia de la pregunta con los datos recibidos
        const newQuestion = new Question({
            title: data.pregunta,
            rephrase: data.rephPregunta,
            bloc: block.block,
            type: data.tipusPregunta,
            respostes: data.respostes || [],
            columnes: data.columnes || [],
            abv_respostes: data.abv_respostes || [],
            abv_columnes: data.abv_columnes || []
        });

        // Guardar la nueva pregunta en la base de datos
        const newBlock = await Block.findById(block.block._id);

        if (!newBlock) {
            return res.status(404).send("Bloque no encontrado");
        }
 
        newBlock.questions.push(newQuestion._id);

        // Guardar el bloque actualizado en la base de datos
        await newBlock.save(); 
        await newQuestion.save();

        // Enviar una respuesta de éxito
        res.status(201).json({ message: 'Pregunta agregada exitosamente', questionId: newQuestion._id });
    } catch (error) {
        console.error('Error al agregar la pregunta:', error);
        res.status(500).json({ message: 'Error al agregar la pregunta', error: error.message });
    }
});

app.get('/get-block', async (req, res) => {
    const { id } = req.query;

    try {
        const block = await Block.findById(id);
        
        if (!block) {
            return res.status(404).json({ error: 'Formulario no encontrado' });
        }

        res.status(200).json({ block });
    } catch (error) {
        console.error("Error al obtener los detalles del formulario:", error);
        res.status(500).json({ error: 'Error al obtener los detalles del formulario' });
    }
});

app.get('/get-question', async (req, res) => {
    const { id } = req.query;

    try {
        const question = await Question.findById(id);
        
        if (!question) {
            return res.status(404).json({ error: 'Formulario no encontrado' });
        }

        res.status(200).json({ question });
    } catch (error) {
        console.error("Error al obtener los detalles del formulario:", error);
        res.status(500).json({ error: 'Error al obtener los detalles del formulario' });
    }
});


app.get('/search-blocks', async (req, res) => {
    try {
        const query = req.query.query; // Término de búsqueda
        if (!query) {
            return res.status(400).json({ error: 'Debe proporcionar un término de búsqueda' });
        }

        // Realiza la búsqueda en la base de datos
        const blocks = await Block.find({ 
            title: { $regex: query, $options: 'i' } // Búsqueda que no distingue entre mayúsculas y minúsculas
        }).limit(10); // Limita los resultados a 10

        res.json(blocks); // Envía los resultados como JSON
    } catch (error) {
        console.error("Error al buscar bloques:", error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

app.put('/add-block-to-form', async (req, res) => {
    const { formId, blockId } = req.body;

    try {
        // Encuentra y actualiza el formulario, añadiendo el ID del bloque al array de bloques
        await Form.findByIdAndUpdate(formId, {
            $push: { bloques: blockId }
        });

        res.status(200).send('Bloque añadido al formulario correctamente.');
    } catch (error) {
        console.error('Error al actualizar el formulario:', error);
        res.status(500).send('Error al añadir el bloque al formulario.');
    }
});

app.post('/remove-question-from-block/:blockId', (req, res) => {
    const blockId = req.params.blockId;
    const { questionId } = req.body;

    console.log(blockId, questionId);

    // Elimina el ID del bloque del array 'questions' del bloque
    Block.findByIdAndUpdate(
        blockId,
        { $pull: { questions: questionId } }, // Elimina el ID de la pregunta del bloque
        { new: true } // Devuelve el bloque actualizado
    )
    .then(updatedBlock => {
        if (!updatedBlock) {
            return res.status(404).send('Bloque no encontrado');
        }
        Question.findByIdAndDelete(questionId)
            .then(() => {
                res.status(200).send('Pregunta eliminada del bloque y de la base de datos');
            })
            .catch(error => {
                console.error('Error al eliminar la pregunta:', error);
                res.status(500).send('Error al eliminar la pregunta');
            });
    })
    .catch(error => {
        console.error('Error al actualizar el bloque:', error);
        res.status(500).send('Error al actualizar el bloque');
    });
});


app.post('/remove-block-from-form/:blockId', (req, res) => {
    const blockId = req.params.blockId;
    const { formId } = req.body;

    Form.findByIdAndUpdate(
        formId,
        { $pull: { bloques: blockId } }, // Elimina el ID de la pregunta del bloque
        { new: true } // Devuelve el bloque actualizado
    )
    .then(updatedQuestion => {
        if (!updatedQuestion) {
            return res.status(404).send('Form no encontrada');
        }
        renderObjects();
    })
    .catch(error => {
        console.error('Error al actualizar el form:', error);
        res.status(500).send('Error al actualizar el form');
    });
});

app.post('/create-csv', (req, res) => {
    const { fileName, csvContent } = req.body; 

    try { 
        // Directorio temporal
        const tempDir = path.join(__dirname, 'public', 'csv_files');         
        const filePath = path.join(tempDir, fileName); 
        const csvString = csvContent.join('\n');

        // Escribir el archivo CSV
        fs.writeFileSync(filePath, csvString + '\n');
 
        res.status(200).json({ filePath });
    } catch (error) {
        console.error('Error al crear el archivo CSV:', error);
        res.status(500).send('Error al crear el archivo CSV');
    }
});
 

app.post('/run-r-script', (req, res) => { 
    blocksCSV = req.body.b
    questionCSV = req.body.q
    formsName = req.body.formName
    const scriptPath = path.join(__dirname, 'MetadataProcess', 'MetadataExtraction_Params.R');

    const command = `Rscript ${scriptPath} "${blocksCSV}" "${questionCSV}"`; 

    exec(command, (error, stdout, stderr) => {
        if (error) {
            console.error(`Error al ejecutar el script de R: ${error.message}`);
            return res.status(500).send(`Error al ejecutar el script de R: ${error.message}`);
        }
        if (stderr) {
            console.error(`Error en el script de R: ${stderr}`);
            return res.status(500).send(`Error en el script de R: ${stderr}`);
        }
        try {
            console.log(stdout)
            const metadata = JSON.parse(stdout); 
            console.log(metadata)
 
            const csv = json2csv(metadata);  
            const filePath = path.join(__dirname, 'public', 'csv_files', 'MetaData_Obtained.csv');

            fs.writeFile(filePath, csv, (err) => {
                if (err) {
                    console.error('Error al escribir el archivo CSV: ', err);
                    return res.status(500).send('Error al generar el archivo CSV.');
                } 
                
             });
            
             res.status(200).json({ filePath });
        } catch (err) {
            console.error(`JSON parse error: ${err}`);
            return res.status(500).send({ error: 'Error parsing R output' });
        }
    });
});



app.post('/add-url', async (req, res) => {
    const { formId, url } = req.body;

    try {
        // Busca el formulario por ID
        const form = await Form.findById(formId);

        if (!form) {
            return res.status(404).send('Formulario no encontrado');
        }

        // Guarda la URL en el campo 'url'
        form.url = url;

        // Guarda el formulario actualizado
        await form.save();
        console.log('URL guardada correctamente en el formulario');
        res.status(200).send('URL guardada');
    } catch (err) {
        console.error('Error al encontrar o guardar el formulario:', err);
        res.status(500).send('Error al guardar la URL');
    }
});


app.post('/run-python-script', async (req, res) => {
    try {
        const scriptPath = path.join(__dirname, 'MetadataProcess', 'formulariInicial.py');
        const command = `python ${scriptPath}`;

        exec(command, (error, stdout, stderr) => {
            if (error) {
                console.error(`Error al ejecutar el script de Python: ${error.message}`);
                return res.status(500).send(`Error al ejecutar el script de Python: ${error.message}`);
            }
            if (stderr) {
                console.error(`Error en el script de Python: ${stderr}`);
                return res.status(500).send(`Error en el script de Python: ${stderr}`);
            } 
            res.send(stdout);
        });
    } catch (error) {
        console.error('Error ejecutando el script de Python:', error);
        return res.status(500).send('Error ejecutando el script de Python');
    }
});

// Iniciar el servidor en el puerto 3000
const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Servidor iniciado en http://localhost:${PORT}`);
    /* const appUrl = 'http://localhost:3000';
    exec(`start ${appUrl}`, (err, stdout, stderr) => {
        if (err) {
           console.error('Error al abrir el navegador:', err);
           return;
        }
        console.log('Navegador abierto correctamente');
    }); */
  });
