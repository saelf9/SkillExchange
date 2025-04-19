<script setup>
import { ref } from 'vue';

const showFilters = ref(false);

const toggleFilters = () => {
  showFilters.value = !showFilters.value;
};

const applyFilters = () => {
  console.log("Filtres appliqués !");
  showFilters.value = false; 
};
</script>

<template>
  <div class="filter-container d-flex align-items-center">
    <img 
      src="@/assets/filter_icon.png" 
      alt="Filtrer" 
      class="filter-icon"
      @click="toggleFilters"
    />

    <div v-if="showFilters" class="filter-section">
      <h3>Filtres</h3>
      
      <div class="filter-group">
        <label>
          <input type="checkbox" /> Femme       
        </label>
      </div>

      <div class="filter-group">
        <label>
          <input type="checkbox" /> Homme
        </label>
      </div>

      <div class="filter-group">
        <label>
          <input type="checkbox" /> Moins de 18 ans 
        </label>
      </div>

      <div class="filter-group">
        <label>
          <input type="checkbox" /> Plus de 18 ans
        </label>
      </div>

      <!-- Bouton Appliquer -->
      <button class="apply-button" @click="applyFilters">Appliquer</button>
    </div>
  </div>
</template>

<style scoped>
.filter-container {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  margin-left: auto;
}

/* Icône du filtre */
.filter-icon {
  width: 40px;
  cursor: pointer;
  transition: transform 0.2s ease-in-out;
}

.filter-icon:hover {
  transform: scale(1.1);
}

/* Section Filtres */
.filter-section {
  position: absolute;
  top: 50px;
  right: 0;
  background: rgb(249, 246, 246);
  border: 1px solid #ddd;
  padding: 15px;
  box-shadow: 3px 3px 6px rgba(0, 0, 0, 0.1);
  border-radius: 5px;
  min-width: 200px;
  z-index: 1000;
}

/* Alignement des options */
.filter-group {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 5px 0;
}

/* Bouton Appliquer */
.apply-button {
  width: 100%;
  margin-top: 10px;
  padding: 8px;
  border: none;
  border-radius: 5px;
  background: #007bff;
  color: white;
  font-size: 14px;
  cursor: pointer;
}

.apply-button:hover {
  background: #0056b3;
}

/* Responsive design */
@media (max-width: 768px) { /* Smartphones */
  .filter-section {
    width: 90%;
    right: 10px;
  }
}

@media (min-width: 769px) and (max-width: 1024px) { /* Tablettes */
  .filter-section {
    width: 250px;
    right: 20px;
  }
}

@media (min-width: 1025px) { /* Ordinateurs */
  .filter-section {
    width: 300px;
    right: 30px;
  }
}
</style>
