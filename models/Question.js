// models/Question.js
const mongoose = require("mongoose");

const questionSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true,
    },
    rephrase: {
        type: String,
        required: true,
    },
    bloc: {
        type: mongoose.Schema.Types.ObjectId,  // Usar ObjectId para almacenar las referencias de los bloques
        ref: 'Block',  // Hace referencia al modelo de Block
    },
    type: {
        type: String,
        required: true,
    },
    respostes: {
        type: [String],
        required: true,
    },
    columnes: {
        type: [String],
        required: true,
    },
    abv_respostes: {
        type: [String],
        required: true,
    },
    abv_columnes: {
        type: [String],
        required: true,
    },
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

const Question = mongoose.model("Question", questionSchema);

module.exports = Question;
