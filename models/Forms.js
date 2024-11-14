const mongoose = require('mongoose');

// Definición del esquema de Formulario
const formSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true,
    },
    createdAt: {
        type: Date,
        default: Date.now,
    },
    author: {
        type: String,
    },
    bloques: {
        type: [mongoose.Schema.Types.ObjectId],  // Usar ObjectId para almacenar las referencias de los bloques
        ref: 'Block',  // Hace referencia al modelo de Block
    },
    url: {
        type: String,  // Define el campo de URL como un String
    },
});

module.exports = mongoose.model('Form', formSchema);
