<template>
  <div class="profile-page">
    <div class="profile-header">
      <img :src="profilePicture" alt="Profile Picture" class="profile-pic">
      <div class="profile-info">
        <h2>{{ username }}</h2>
        <p class="bio">{{ bio }}</p>
        <div class="stats">
          <span><strong>{{ posts.length }}</strong> Posts</span>
          <span><strong>{{ followers }}</strong> Followers</span>
          <span><strong>{{ following }}</strong> Following</span>
        </div>
      </div>
    </div>

    <div class="posts-grid">
      <div v-for="(post, index) in posts" :key="index" class="post">
        <img :src="post.image" alt="Post Image">
      </div>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      username: "",
      bio: "This user has no bio yet.",
      profilePicture: require("@/assets/image2.png"),
      posts: [],
      followers: 100,
      following: 50
    };
  },
  created() {
    this.username = this.$route.params.username;
  }
};
</script>
