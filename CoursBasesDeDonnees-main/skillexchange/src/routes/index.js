import { createRouter, createWebHistory } from 'vue-router';
import UserAuthentification from '../components/UserAuthentification.vue';
import HomePage from '../components/HomePage.vue';
import ProfilePage from '../components/Profile.vue';
import Conversation from '@/components/Conversation.vue';

console.log("Vue Router is being initialized!");

const routes = [
    { path: '/', name: 'UserAuthentification', component: UserAuthentification },
    { path: '/home', name: 'HomePage', component: HomePage },
    { path: '/profile/:username', name: 'ProfilePage', component: ProfilePage },
    { path: '/conversation', name: 'Conversation', component: Conversation }
];

const router = createRouter({
    history: createWebHistory(),
    routes
});

export default router;
