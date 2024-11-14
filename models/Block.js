// models/Block.js
const mongoose = require("mongoose");

const blockSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true,
    },
    questions: [{
        type: String,  // Aquí podrías agregar objetos más complejos si las preguntas tienen más atributos
    }],
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

const Block = mongoose.model("Block", blockSchema);

module.exports = Block;
