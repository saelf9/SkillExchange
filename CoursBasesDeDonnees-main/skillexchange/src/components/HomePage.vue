<template>
  <div class="home-page">
    <!-- Create Post Section -->
    <div class="create-post">
      <div class="create-post-header">
        <img src="@/assets/image2.png" alt="User" class="user-avatar">
        <textarea v-model="newPostText" placeholder="What's happening?" rows="2"></textarea>
      </div>
      <div class="create-post-footer">
        <input type="file" @change="handleImageUpload">
        <button @click="addPost">Post</button>
      </div>
    </div>

    <!-- Post Feed -->
    <div class="feed">
      <div v-for="(post, index) in posts" :key="index" class="post">
        <div class="post-header">
          <img :src="post.userAvatar" alt="User" class="user-avatar" @click="goToProfile(post.username)">
          <div>
            <h3 @click="goToProfile(post.username)" class="username">@{{ post.username }}</h3>
            <p class="timestamp">{{ post.timestamp }}</p>
          </div>
        </div>

        <p class="post-text">{{ post.text }}</p>
        <img v-if="post.image" :src="post.image" class="post-image">

        <div class="post-actions">
          <button @click="likePost(index)">
            ❤️ {{ post.likes }}
          </button>
          <button @click="toggleComments(index)">
            💬 {{ post.comments.length }} Comments
          </button>
        </div>

        <!-- Comment Section -->
        <div v-if="post.showComments" class="comments-section">
          <div v-for="(comment, cIndex) in post.comments" :key="cIndex" class="comment">
            <p><strong>User:</strong> {{ comment }}</p>
          </div>
          <input v-model="post.newComment" placeholder="Write a comment..." @keyup.enter="addComment(index)">
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      newPostText: "",
      newPostImage: null,
      posts: [
        {
          username: "JohnDoe",
          userAvatar: require("@/assets/image2.png"),
          text: "Exploring Vue.js!",
          image: "https://source.unsplash.com/400x300/?tech",
          likes: 10,
          timestamp: "2h ago",
          comments: [],
          showComments: false,
          newComment: ""
        },
        {
          username: "JaneSmith",
          userAvatar: require("@/assets/image3.png"),
          text: "Loving this community!",
          image: "https://source.unsplash.com/400x300/?nature",
          likes: 5,
          timestamp: "5h ago",
          comments: [],
          showComments: false,
          newComment: ""
        }
      ]
    };
  },
  methods: {
    addPost() {
      if (this.newPostText.trim() === "" && !this.newPostImage) return;
      this.posts.unshift({
        username: "CurrentUser",
        userAvatar: require("@/assets/image2.png"),
        text: this.newPostText,
        image: this.newPostImage,
        likes: 0,
        timestamp: "Just now",
        comments: [],
        showComments: false,
        newComment: ""
      });
      this.newPostText = "";
      this.newPostImage = null;
    },
    goToProfile(username) {
      this.$router.push(`/profile/${username}`);
    },
    handleImageUpload(event) {
      const file = event.target.files[0];
      if (file) {
        const reader = new FileReader();
        reader.onload = () => {
          this.newPostImage = reader.result;
        };
        reader.readAsDataURL(file);
      }
    },
    likePost(index) {
      this.posts[index].likes++;
    },
    toggleComments(index) {
      this.posts[index].showComments = !this.posts[index].showComments;
    },
    addComment(index) {
      if (this.posts[index].newComment.trim() !== "") {
        this.posts[index].comments.push(this.posts[index].newComment);
        this.posts[index].newComment = "";
      }
    }
  }
};
</script>

<style scoped>
/* General Styling */
.home-page {
  font-family: 'Arial', sans-serif;
  background-color: #FEF8EC;
  padding: 20px;
}

/* Create Post */
.create-post {
  background: white;
  padding: 15px;
  border-radius: 10px;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
  margin-bottom: 20px;
}

.create-post-header {
  display: flex;
  align-items: center;
}

.create-post-header textarea {
  flex: 1;
  border: none;
  resize: none;
  padding: 10px;
  font-size: 16px;
}

.create-post-footer {
  display: flex;
  justify-content: space-between;
  padding-top: 10px;
}

.create-post-footer button {
  background: #333;
  color: white;
  border: none;
  padding: 8px 12px;
  cursor: pointer;
  border-radius: 5px;
}

.create-post-footer button:hover {
  background: #555;
}

/* Post Feed */
.feed {
  width: 90%;
  max-width: 600px;
  margin: auto;
}

/* Post Card */
.post {
  background: white;
  padding: 15px;
  margin: 15px 0;
  border-radius: 10px;
  box-shadow: 0px 4px 6px rgba(0, 0, 0, 0.1);
  text-align: left;
}

.post-header {
  display: flex;
  align-items: center;
  margin-bottom: 10px;
}

.user-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  margin-right: 10px;
}

.username {
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  color: #007bff;
}

.username:hover {
  text-decoration: underline;
}

.timestamp {
  font-size: 12px;
  color: gray;
}

.post-text {
  font-size: 16px;
  color: #333;
}

.post-image {
  width: 100%;
  border-radius: 8px;
  margin-top: 10px;
}

/* Post Actions */
.post-actions {
  display: flex;
  justify-content: space-between;
  margin-top: 10px;
}

.post-actions button {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 14px;
  color: gray;
}

.post-actions button:hover {
  color: black;
}

/* Comments Section */
.comments-section {
  text-align: left;
  margin-top: 10px;
}

.comment {
  background: #f1f1f1;
  padding: 5px;
  margin: 5px 0;
  border-radius: 5px;
}

.comments-section input {
  width: 100%;
  padding: 8px;
  margin-top: 5px;
  border: 1px solid #ddd;
  border-radius: 5px;
}
</style>
