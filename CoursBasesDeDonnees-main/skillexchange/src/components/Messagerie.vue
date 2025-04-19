<template>
  <div class="conversation-container">
    <!-- Barre latérale des conversations avec toggle pour mobile -->
    <div class="sidebar" :class="{ 'sidebar-open': isSidebarOpen }">
      <div class="sidebar-header">
        <h3>Conversations</h3>
        <button class="new-chat-btn">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <line x1="12" y1="5" x2="12" y2="19"></line>
            <line x1="5" y1="12" x2="19" y2="12"></line>
          </svg>
        </button>
      </div>
      
      <div class="search-box">
        <input type="text" placeholder="Rechercher..." v-model="searchQuery" />
      </div>
      
      <div class="conversation-list">
        <div 
          v-for="convo in filteredConversations" 
          :key="convo.id" 
          class="conversation-item"
          :class="{ 'active': activeConversationId === convo.id }"
          @click="setActiveConversation(convo.id)"
        >
          <div class="avatar">
            <img :src="convo.avatar" :alt="convo.name" />
            <span class="status-dot" :class="{ 'online': convo.isOnline }"></span>
          </div>
          <div class="conversation-info">
            <div class="conversation-name">{{ convo.name }}</div>
            <div class="last-message">{{ convo.lastMessage }}</div>
          </div>
          <div class="conversation-meta">
            <div class="time">{{ formatTime(convo.lastMessageTime) }}</div>
            <div v-if="convo.unreadCount > 0" class="unread-count">{{ convo.unreadCount }}</div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Zone de chat active -->
    <div class="chat-area">
      <div v-if="activeConversation" class="chat-content">
        <div class="chat-header">
          <!-- Bouton de retour pour mobile -->
          <button class="back-button" @click="toggleSidebar">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <line x1="19" y1="12" x2="5" y2="12"></line>
              <polyline points="12 19 5 12 12 5"></polyline>
            </svg>
          </button>
          
          <div class="user-info">
            <div class="avatar">
              <img :src="activeConversation.avatar" :alt="activeConversation.name" />
              <span class="status-dot" :class="{ 'online': activeConversation.isOnline }"></span>
            </div>
            <div>
              <div class="user-name">{{ activeConversation.name }}</div>
              <div class="user-status">{{ activeConversation.isOnline ? 'En ligne' : 'Hors ligne' }}</div>
            </div>
          </div>
          
          <button class="options-button">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <circle cx="12" cy="12" r="1"></circle>
              <circle cx="12" cy="5" r="1"></circle>
              <circle cx="12" cy="19" r="1"></circle>
            </svg>
          </button>
        </div>
        
        <div class="messages-container" ref="messagesContainer">
          <div class="date-separator">
            <span>{{ formatDate(new Date()) }}</span>
          </div>
          
          <div 
            v-for="(message, index) in activeConversation.messages" 
            :key="index"
            class="message"
            :class="{ 'outgoing': message.isOutgoing }"
          >
            <div class="message-content">
              <div class="message-text">{{ message.text }}</div>
              <div class="message-time">{{ formatMessageTime(message.timestamp) }}</div>
            </div>
          </div>
        </div>
        
        <div class="message-input">
          <button class="attachment-button">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"></path>
            </svg>
          </button>
          <textarea 
            v-model="newMessage" 
            placeholder="Tapez un message..." 
            @keyup.enter.prevent="sendMessage"
            rows="1"
          ></textarea>
          <button class="send-button" @click="sendMessage" :disabled="!newMessage.trim()">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <line x1="22" y1="2" x2="11" y2="13"></line>
              <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
            </svg>
          </button>
        </div>
      </div>
      
      <div v-else class="no-conversation-selected">
        <div class="empty-state">
          <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
          </svg>
          <p>Sélectionnez une conversation pour commencer</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick, onMounted, defineProps, defineEmits, defineExpose, onUnmounted } from 'vue';

// Props
const props = defineProps({
  conversations: {
    type: Array,
    default: () => []
  },
  userId: {
    type: String,
    required: true
  }
});

// Emits
const emit = defineEmits(['message-sent', 'conversation-selected']);

// Reactive state
const conversationsList = ref([...props.conversations]);
const activeConversationId = ref(null);
const newMessage = ref('');
const searchQuery = ref('');
const messagesContainer = ref(null);
const isSidebarOpen = ref(window.innerWidth > 768); // Sidebar ouvert par défaut sur desktop, fermé sur mobile

// Détecter les changements de taille d'écran
const handleResize = () => {
  isSidebarOpen.value = window.innerWidth > 768;
};

// Ajouter/supprimer l'écouteur d'événement de redimensionnement
onMounted(() => {
  window.addEventListener('resize', handleResize);
});

onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
});

// Toggle sidebar (pour mobile)
const toggleSidebar = () => {
  isSidebarOpen.value = !isSidebarOpen.value;
};

const filteredConversations = computed(() => {
  if (!searchQuery.value) return conversationsList.value;
  
  const query = searchQuery.value.toLowerCase();
  return conversationsList.value.filter(convo => 
    convo.name.toLowerCase().includes(query) || 
    convo.lastMessage.toLowerCase().includes(query)
  );
});

const activeConversation = computed(() => {
  if (!activeConversationId.value) return null;
  return conversationsList.value.find(convo => convo.id === activeConversationId.value);
});

// Methods
const formatTime = (timestamp) => {
  const date = new Date(timestamp);
  const now = new Date();
  
  if (date.toDateString() === now.toDateString()) {
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  } else {
    return date.toLocaleDateString([], { day: '2-digit', month: '2-digit' });
  }
};

const formatMessageTime = (timestamp) => {
  return new Date(timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
};

const formatDate = (date) => {
  const options = { weekday: 'long', day: 'numeric', month: 'long' };
  return date.toLocaleDateString(undefined, options);
};

const setActiveConversation = (convoId) => {
  activeConversationId.value = convoId;
  emit('conversation-selected', convoId);
  
  // Mark messages as read
  const conversation = conversationsList.value.find(c => c.id === convoId);
  if (conversation) {
    conversation.unreadCount = 0;
  }
  
  // Sur mobile, fermer la sidebar quand une conversation est sélectionnée
  if (window.innerWidth <= 768) {
    isSidebarOpen.value = false;
  }
  
  // Scroll to bottom on next tick
  nextTick(() => {
    scrollToBottom();
  });
};

const scrollToBottom = () => {
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight;
  }
};

const sendMessage = () => {
  if (!newMessage.value.trim() || !activeConversationId.value) return;
  
  const message = {
    text: newMessage.value,
    isOutgoing: true,
    timestamp: new Date()
  };
  
  // Find the active conversation and add the message
  const conversation = conversationsList.value.find(c => c.id === activeConversationId.value);
  if (conversation) {
    conversation.messages.push(message);
    conversation.lastMessage = message.text;
    conversation.lastMessageTime = message.timestamp;
  }
  
  // Emit the message
  emit('message-sent', {
    conversationId: activeConversationId.value,
    message
  });
  
  newMessage.value = '';
  
  // Scroll to bottom on next tick
  nextTick(() => {
    scrollToBottom();
  });
};

// Method to add a received message
const addMessage = (conversationId, message) => {
  const conversation = conversationsList.value.find(c => c.id === conversationId);
  if (!conversation) return;
  
  // Add the message
  conversation.messages.push({
    text: message.text,
    isOutgoing: false,
    timestamp: message.timestamp || new Date()
  });
  
  // Update the last message
  conversation.lastMessage = message.text;
  conversation.lastMessageTime = message.timestamp || new Date();
  
  // If this isn't the active conversation, increment unread count
  if (activeConversationId.value !== conversationId) {
    conversation.unreadCount += 1;
  }
  
  // If this is the active conversation, scroll to bottom
  if (activeConversationId.value === conversationId) {
    nextTick(() => {
      scrollToBottom();
    });
  }
};

// Expose methods to parent
defineExpose({
  addMessage,
  setActiveConversation
});

// Watch for changes in props.conversations
watch(() => props.conversations, (newVal) => {
  conversationsList.value = [...newVal];
}, { deep: true });

// Scroll to bottom when component is mounted
onMounted(() => {
  // If there are conversations, set the first one as active
  if (conversationsList.value.length > 0 && !activeConversationId.value) {
    setActiveConversation(conversationsList.value[0].id);
  }
});
</script>

<style scoped>
.conversation-container {
  display: flex;
  height: 100%;
  min-height: 500px;
  background-color: #fff;
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  position: relative;
}

/* Sidebar styles */
.sidebar {
  width: 320px;
  border-right: 1px solid #eaeaea;
  display: flex;
  flex-direction: column;
  background-color: #f9f9f9;
  transition: transform 0.3s ease;
  z-index: 10;
}

.back-button, .options-button {
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 5px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #4a5568;
}

.back-button {
  display: none; /* Caché par défaut sur desktop */
}

.sidebar-header {
  padding: 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #eaeaea;
}

.sidebar-header h3 {
  margin: 0;
  font-size: 1.2rem;
}

.new-chat-btn {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  background-color: #f0f2f5;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: #4a5568;
}

.search-box {
  padding: 12px 16px;
  border-bottom: 1px solid #eaeaea;
}

.search-box input {
  width: 100%;
  padding: 8px 12px;
  border-radius: 20px;
  border: 1px solid #e2e8f0;
  background-color: #f0f2f5;
  font-size: 0.9rem;
}

.conversation-list {
  flex: 1;
  overflow-y: auto;
}

.conversation-item {
  padding: 12px 16px;
  display: flex;
  align-items: center;
  cursor: pointer;
  transition: background-color 0.2s;
  border-bottom: 1px solid #f0f2f5;
}

.conversation-item:hover {
  background-color: #f0f2f5;
}

.conversation-item.active {
  background-color: #e9f5fe;
}

.avatar {
  position: relative;
  width: 44px;
  height: 44px;
  border-radius: 50%;
  overflow: hidden;
  margin-right: 12px;
  flex-shrink: 0;
}

.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.status-dot {
  position: absolute;
  bottom: 2px;
  right: 2px;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background-color: #a0aec0;
  border: 2px solid #fff;
}

.status-dot.online {
  background-color: #48bb78;
}

.conversation-info {
  flex: 1;
  min-width: 0;
}

.conversation-name {
  font-weight: 500;
  font-size: 0.95rem;
  margin-bottom: 4px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.last-message {
  font-size: 0.85rem;
  color: #718096;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.conversation-meta {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  margin-left: 10px;
}

.time {
  font-size: 0.75rem;
  color: #a0aec0;
  margin-bottom: 4px;
}

.unread-count {
  background-color: #4299e1;
  color: white;
  font-size: 0.75rem;
  font-weight: 500;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
}

/* Chat area styles */
.chat-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  background-color: #fff;
}

.chat-header {
  padding: 12px 16px;
  border-bottom: 1px solid #eaeaea;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.user-info {
  display: flex;
  align-items: center;
}

.user-name {
  font-weight: 500;
  font-size: 1rem;
}

.user-status {
  font-size: 0.8rem;
  color: #718096;
}

.messages-container {
  flex: 1;
  padding: 16px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 8px;
  background-color: #f0f2f5;
  background-image: url("data:image/svg+xml,%3Csvg width='100' height='100' viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M11 18c3.866 0 7-3.134 7-7s-3.134-7-7-7-7 3.134-7 7 3.134 7 7 7zm48 25c3.866 0 7-3.134 7-7s-3.134-7-7-7-7 3.134-7 7 3.134 7 7 7zm-43-7c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zm63 31c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zM34 90c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zm56-76c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zM12 86c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm28-65c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm23-11c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm-6 60c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm29 22c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zM32 63c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm57-13c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm-9-21c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM60 91c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM35 41c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM12 60c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2z' fill='%23dcdcdc' fill-opacity='0.1' fill-rule='evenodd'/%3E%3C/svg%3E");
}

.date-separator {
  text-align: center;
  margin: 12px 0;
  position: relative;
}

.date-separator::before {
  content: '';
  position: absolute;
  left: 0;
  top: 50%;
  width: 100%;
  height: 1px;
  background-color: #e2e8f0;
  z-index: 0;
}

.date-separator span {
  background-color: #f0f2f5;
  padding: 0 12px;
  font-size: 0.75rem;
  color: #718096;
  position: relative;
  z-index: 1;
}
/* Modification de la classe message pour assurer un meilleur rendu */
.message {
  display: flex;
  max-width: 70%;
  margin-bottom: 8px; /* Ajoute un espace entre les messages */
}

.message.outgoing {
  align-self: flex-end;
  justify-content: flex-end; /* Assure que le contenu est aligné à droite */
}

.message-content {
  padding: 10px 12px;
  border-radius: 16px;
  background-color: #fff;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
  position: relative;
  word-wrap: break-word; /* Assure que le texte se wrap correctement */
  max-width: 100%; /* Assure que le contenu ne dépasse pas de la bulle */
}

/* Ajuster la forme des bulles pour avoir un style plus arrondi d'un côté */
.message:not(.outgoing) .message-content {
  border-top-left-radius: 4px; /* Coin supérieur gauche moins arrondi */
}

.message.outgoing .message-content {
  background-color: #dcf8c6;
  color: #000;
  border-top-right-radius: 4px; /* Coin supérieur droit moins arrondi */
}

.message-text {
  font-size: 0.95rem;
  word-break: break-word;
  white-space: pre-wrap; /* Préserve les espaces et retours à la ligne */
}

.message-time {
  font-size: 0.7rem;
  text-align: right;
  margin-top: 2px;
  opacity: 0.7;
}

.message-input {
  padding: 12px 16px;
  display: flex;
  align-items: center;
  gap: 10px;
  border-top: 1px solid #eaeaea;
}

.attachment-button {
  background: transparent;
  border: none;
  color: #4a5568;
  cursor: pointer;
  padding: 5px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.message-input textarea {
  flex: 1;
  padding: 10px 14px;
  border-radius: 20px;
  border: 1px solid #e2e8f0;
  background-color: #f0f2f5;
  resize: none;
  font-family: inherit;
  max-height: 100px;
  min-height: 40px;
  font-size: 0.95rem;
}

.send-button {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  background-color: #128C7E; /* Couleur WhatsApp */
  color: white;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.send-button:disabled {
  background-color: #cbd5e0;
  cursor: not-allowed;
}

.no-conversation-selected {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

.empty-state {
  text-align: center;
  color: #a0aec0;
}

.empty-state svg {
  margin-bottom: 16px;
}

.empty-state p {
  font-size: 1rem;
}

.chat-content {
  display: flex;
  flex-direction: column;
  height: 100%;
}

/* Media queries pour la responsivité */
@media (max-width: 768px) {
  .conversation-container {
    flex-direction: column;
  }
  
  .sidebar {
    position: absolute;
    top: 0;
    left: 0;
    bottom: 0;
    width: 100%;
    transform: translateX(-100%);
    z-index: 100;
  }
  
  .sidebar-open {
    transform: translateX(0);
  }
  
  .back-button {
    display: flex; /* Afficher sur mobile */
  }
  
  .message {
    max-width: 85%;
  }
}

/* Pour les appareils très petits */
@media (max-width: 480px) {
  .message {
    max-width: 90%;
  }
  
  .message-input {
    padding: 8px;
  }
  
  .chat-header {
    padding: 8px 12px;
  }
  
  .avatar {
    width: 36px;
    height: 36px;
  }
}
</style>