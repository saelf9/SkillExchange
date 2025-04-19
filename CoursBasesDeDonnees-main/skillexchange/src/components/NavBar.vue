<template>
  <nav class="navbar navbar-expand-lg bg-body-tertiary">
    <div class="container-fluid">
      <!-- Navbar Brand (Left Side) -->
      <a class="navbar-brand" href="#">Navbar</a>

      <!-- Navbar Content (Always Visible) -->
      <div class="navbar-nav d-flex w-100 justify-content-between">
        <!-- Left Navigation Links -->
        <div class="d-flex">
          <router-link class="nav-link" to="/home">Home</router-link>
          <router-link class="nav-link" to="/conversation">Conversation</router-link>
        </div>

        <!-- Centered Search Bar -->
        <form class="d-flex search-form">
          <input class="form-control search-input" type="search" placeholder="Search" aria-label="Search">
          <button class="btn search-btn" type="submit">Search</button>
        </form>

        <!-- Right Side Icons (Filters & Profile) -->
        <div class="d-flex align-items-center">
          <!-- Filters Icon -->
          <Filters />

          <!-- Profile Icon with Dropdown -->
          <div class="profile-dropdown">
            <span class="profile-icon" @click="toggleProfileMenu">👤</span>
            <div v-if="showProfileMenu" class="profile-menu">
              <router-link class="profile-option" to="/profile">View Profile</router-link>
              <button class="profile-option" @click="logout">Logout</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </nav>
</template>

<script setup>
import { ref } from 'vue';
import Filters from '@/components/Filters.vue';

const showProfileMenu = ref(false);

const toggleProfileMenu = () => {
  showProfileMenu.value = !showProfileMenu.value;
};

const logout = () => {
  console.log("Logging out...");
  // Implement logout functionality
};
</script>

<style scoped>
.navbar {
  background-color: #ffffff;
  border-bottom: 1px solid #ddd;
  padding: 10px 20px;
}

/* Centering the search bar */
.search-form {
  display: flex;
  justify-content: center;
  align-items: center;
}

.search-input {
  flex-grow: 1;
  border: 1px solid #ddd;
  border-radius: 5px;
  padding: 8px;
}

.search-btn {
  background-color: #8A9A5B;
  color: white;
  border: none;
  padding: 8px 15px;
  margin-left: 5px;
  border-radius: 5px;
  cursor: pointer;
}

.search-btn:hover {
  background-color: #6e7d3b;
}

/* Right-side container */
.d-flex.align-items-center {
  gap: 15px;
}

/* Profile Dropdown */
.profile-dropdown {
  position: relative;
  display: flex;
  align-items: center;
}

.profile-icon {
  font-size: 24px;
  cursor: pointer;
}

.profile-menu {
  position: absolute;
  top: 50px;
  right: 0;
  background: white;
  border: 1px solid #ddd;
  box-shadow: 0px 4px 6px rgba(0, 0, 0, 0.1);
  border-radius: 5px;
  width: 150px;
  display: flex;
  flex-direction: column;
}

.profile-option {
  padding: 10px;
  text-align: left;
  border: none;
  background: none;
  cursor: pointer;
  width: 100%;
  text-decoration: none;
  color: black;
}

.profile-option:hover {
  background: #f5f5f5;
}
</style>
