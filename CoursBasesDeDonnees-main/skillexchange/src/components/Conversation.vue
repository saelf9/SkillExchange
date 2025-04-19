<script setup>
import Messagerie from './Messagerie.vue';
import { ref } from 'vue';

const userId = ref('user1');

// Exemple de données de conversations
const conversationsData = ref([
  {
    id: 'conv1',
    name: 'Thomas Martin',
    avatar: 'https://i.pravatar.cc/150?img=1',
    isOnline: true,
    lastMessage: 'On se voit demain pour le projet ?',
    lastMessageTime: new Date(Date.now() - 30 * 60000),
    unreadCount: 2,
    messages: [
      {
        text: 'Bonjour, comment vas-tu ?',
        isOutgoing: false,
        timestamp: new Date(Date.now() - 120 * 60000)
      },
      {
        text: 'Très bien merci, et toi ?',
        isOutgoing: true,
        timestamp: new Date(Date.now() - 118 * 60000)
      },
      {
        text: 'Super ! J\'ai une question sur le projet.',
        isOutgoing: false,
        timestamp: new Date(Date.now() - 95 * 60000)
      },
      {
        text: 'On se voit demain pour le projet ?',
        isOutgoing: false,
        timestamp: new Date(Date.now() - 30 * 60000)
      }
    ]
  },
  {
    id: 'conv2',
    name: 'Sophie Dubois',
    avatar: 'https://i.pravatar.cc/150?img=5',
    isOnline: false,
    lastMessage: 'Je t\'envoie les documents ce soir',
    lastMessageTime: new Date(Date.now() - 2 * 3600000),
    unreadCount: 0,
    messages: [
      {
        text: 'Salut, as-tu reçu mes fichiers ?',
        isOutgoing: false,
        timestamp: new Date(Date.now() - 5 * 3600000)
      },
      {
        text: 'Oui merci, je les regarde ce soir',
        isOutgoing: true,
        timestamp: new Date(Date.now() - 4 * 3600000)
      },
      {
        text: 'Parfait, j\'attends ton retour',
        isOutgoing: false,
        timestamp: new Date(Date.now() - 3 * 3600000)
      },
      {
        text: 'Je t\'envoie les documents ce soir',
        isOutgoing: true,
        timestamp: new Date(Date.now() - 2 * 3600000)
      }
    ]
  },
  {
    id: 'conv3',
    name: 'Équipe Marketing',
    avatar: 'https://i.pravatar.cc/150?img=8',
    isOnline: true,
    lastMessage: 'Réunion demain à 10h',
    lastMessageTime: new Date(Date.now() - 1 * 86400000),
    unreadCount: 0,
    messages: [
      {
        text: 'Bonjour à tous',
        isOutgoing: false,
        timestamp: new Date(Date.now() - 2 * 86400000)
      },
      {
        text: 'Nous devons planifier la campagne',
        isOutgoing: false,
        timestamp: new Date(Date.now() - 2 * 86400000)
      },
      {
        text: 'Je suis disponible demain',
        isOutgoing: true,
        timestamp: new Date(Date.now() - 1.5 * 86400000)
      },
      {
        text: 'Réunion demain à 10h',
        isOutgoing: false,
        timestamp: new Date(Date.now() - 1 * 86400000)
      }
    ]
  }
]);

const conversationRef = ref(null);

// Gestion d'un nouveau message
const handleMessageSent = ({ conversationId, message }) => {
  console.log(`Message envoyé dans la conversation ${conversationId}:`, message);
  
  // Simuler une réponse après un court délai
  setTimeout(() => {
    const conversation = conversationsData.value.find(c => c.id === conversationId);
    if (conversation) {
      conversationRef.value.addMessage(conversationId, {
        text: `Réponse à: "${message.text}"`,
        timestamp: new Date()
      });
    }
  }, 1500);
};

// Gestion de la sélection d'une conversation
const handleConversationSelected = (conversationId) => {
  console.log(`Conversation sélectionnée: ${conversationId}`);
};
</script>

<template>
  <div style="height: 100vh; width: 100vw;">
    <Messagerie
      ref="conversationRef"
      :conversations="conversationsData"
      :userId="userId"
      @message-sent="handleMessageSent"
      @conversation-selected="handleConversationSelected"
    />
  </div>
</template>