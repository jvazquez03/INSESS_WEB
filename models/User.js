const mongoose = require('mongoose'); 

const Schema = mongoose.Schema;

// Definir el esquema de usuarios
const userSchema = new Schema({
    username: { type: String, required: true },
    password: { type: String, required: true },
    forms: { type: [Object], default: [] }, 
});

const User = mongoose.model('User', userSchema);

module.exports = User;
