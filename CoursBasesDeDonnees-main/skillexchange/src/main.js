import { createApp } from 'vue';
import App from './App.vue';
import router from './routes/index.js';
import 'bootstrap/dist/css/bootstrap.min.css';

console.log("Vue app is initializing...");

const app = createApp(App);
app.use(router);
app.mount('#app');

console.log("Vue app has been mounted successfully!");
