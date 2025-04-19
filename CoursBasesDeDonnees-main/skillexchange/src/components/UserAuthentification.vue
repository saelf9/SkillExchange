<template>
  <div id="auth-page">
    <!-- Hero Section -->
    <section class="hero-section">
      <div class="hero-text">
        <h1>Teach Anything <br> Learn Anytime</h1>
        <button class="cta-btn" @click="scrollToLogin">Get Started</button>
      </div>
      <div class="hero-image">
        <img src="@/assets/image.png" alt="Hero Illustration">
      </div>
    </section>

    <!-- Scroll Down Section -->
    <section ref="loginSection" class="split-section d-flex">
      <div class="left-section">
        <!-- Image Section Next to Login -->
        <div class="image-container">
          <img src="@/assets/image2.png" alt="Illustration 1">
          <img src="@/assets/image3.png" alt="Illustration 2">
        </div>
      </div>

      <div class="right-section d-flex">
        <div class="login-container">
          <h2 class="login-title">Login</h2>
          <form @submit.prevent="login" class="login-form text-center">
            <input type="email" v-model="email" class="form-control mb-3" placeholder="Email Address" required>
            <input type="password" v-model="password" class="form-control mb-3" placeholder="Password" required>
            <button type="submit" class="btn btn-dark w-100 btn-lg">Login</button>
          </form>
          <p class="mt-3" style="color: black;">
            Don't have an account?
            <a href="#" class="register-link" @click.prevent="openRegister">Register</a>
          </p>
        </div>
      </div>
    </section>

    <!-- Register Modal -->
    <div v-if="showRegisterModal" class="modal-overlay">
      <div class="modal-box">
        <h2>Register</h2>
        <form @submit.prevent="register">
          <input type="text" v-model="username" class="form-control mb-3" placeholder="Username" required>
          <input type="email" v-model="registerEmail" class="form-control mb-3" placeholder="Email Address" required>
          <input type="date" v-model="birthdate" class="form-control mb-3" placeholder="Birthdate" required>
          <input type="text" v-model="city" class="form-control mb-3" placeholder="City" required>
          <input type="password" v-model="registerPassword" class="form-control mb-3" placeholder="Password" required>
          <input type="password" v-model="confirmPassword" class="form-control mb-3" placeholder="Confirm Password" required>
          <button type="submit" class="btn btn-dark w-100">Sign Up</button>
          <button @click="closeRegister" class="btn btn-light w-100 mt-2">Cancel</button>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      email: '',
      password: '',
      showRegisterModal: false,
      username: '',
      registerEmail: '',
      birthdate: '',
      city: '',
      registerPassword: '',
      confirmPassword: ''
    };
  },
  methods: {
    login() {
      console.log("Logging in with:", this.email, this.password);
      this.$router.push('/home');  // Redirect to the home page after login
    },
    openRegister() {
      this.showRegisterModal = true;
    },
    closeRegister() {
      this.showRegisterModal = false;
    },
    register() {
      if (this.registerPassword !== this.confirmPassword) {
        alert("Passwords do not match!");
        return;
      }
      console.log("Registering with:", this.username, this.registerEmail, this.birthdate, this.city, this.registerPassword);
      this.closeRegister();
    },
    scrollToLogin() {
      this.$refs.loginSection.scrollIntoView({ behavior: "smooth" });
    }
  }
};
</script>

<style scoped>
/* General Styling */
#auth-page {
  font-family: 'Arial', sans-serif;
  color: white;
  overflow-x: hidden;
}

/* Hero Section */
.hero-section {
  height: 100vh;
  background-color: #FEF8EC;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 100px;
  text-align: left;
  color: black;
}

/* Hero Text */
.hero-text {
  flex: 1;
  max-width: 40%;
  font-size: 28px;
}

.hero-text h1 {
  font-size: 55px;
  font-weight: bold;
  line-height: 1.2;
}

/* Get Started Button */
.cta-btn {
  background: #333;
  color: white;
  border: 2px solid #333;
  padding: 14px 24px;
  font-size: 20px;
  cursor: pointer;
  margin-top: 20px;
  transition: background 0.3s ease, color 0.3s ease;
}

.cta-btn:hover {
  background: white;
  color: #333;
}

/* Hero Image */
.hero-image {
  flex: 1;
  display: flex;
  justify-content: flex-end;
}

.hero-image img {
  width: 500px;
  height: auto;
}

/* Split Section */
.split-section {
  height: 100vh;
  display: flex;
}

/* Left Section (Images) */
.left-section {
  flex: 2;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Hide images on small screens */
.image-container {
  display: flex;
  flex-direction: column;
  gap: 40px;
}

.image-container img {
  width: 400px;
  border-radius: 10px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.2);
}

/* Right Section (Login Panel) */
.right-section {
  flex: 1;
  background: #FEF1E0;
  text-align: center;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 50px 20px;
}

/* Login Panel */
.login-container {
  max-width: 300px;
}

/* Login Title */
.login-title {
  font-size: 40px;
  font-weight: bold;
  margin-bottom: 10px;
  color: black;
}

/* Login Form */
.login-form {
  width: 100%;
}

/* Input Fields */
input.form-control {
  background: rgba(255, 255, 255, 0.9);
  border: none;
  padding: 15px;
  font-size: 18px;
  border-radius: 5px;
}

/* Button */
.btn-dark {
  font-size: 20px;
  padding: 12px;
  background: #333;
  color: white;
  border: none;
  transition: background 0.3s ease;
}

.btn-dark:hover {
  background: #555;
}

/* Register Link */
.register-link {
  color: black;
  font-weight: bold;
  text-decoration: none;
  transition: color 0.3s ease;
}

.register-link:hover {
  color: #e34b2c;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-box {
  background: white;
  padding: 30px;
  border-radius: 10px;
  width: 400px;
  text-align: center;
}

.modal-box h2 {
  margin-bottom: 20px;
  color: black;
}

/* For small phones */
@media (max-width: 1208px) {
  .hero-section {
    flex-direction: column;
    text-align: center;
    padding: 30px 10px;
  }

  .hero-text h1 {
    font-size: 40px;
  }

  .hero-image img {
    width: 250px;
  }

  .split-section {
    flex-direction: column;
    height: auto;
  }

  .left-section {
    display: none; /* Hide images on small screens */
  }

  .right-section {
    width: 100%;
    padding: 30px 10px;
    display: flex;
    justify-content: center;
  }

  .login-container {
    max-width: 250px;
  }

  .modal-box {
    width: 90%;
  }
}
</style>
