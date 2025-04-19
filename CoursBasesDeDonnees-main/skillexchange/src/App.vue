<template>
  <div id="app">
    <NavBar/>
    <router-view></router-view>  <!-- REQUIRED for Vue Router to work -->
  </div>
</template>

<script setup>
import NavBar from './components/NavBar.vue';
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  text-align: center;
  color: #2c3e50;
}
</style>
