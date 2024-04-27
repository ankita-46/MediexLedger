document.addEventListener('DOMContentLoaded', function() {
    const slides = document.querySelectorAll('.slide');
    const totalSlides = slides.length;
    let currentIndex = 0;
  
    function showSlide(index) {
      slides.forEach((slide, i) => {
        slide.style.transform = `translateX(-${index * 100}%)`;
      });
    }
  
    function nextSlide() {
      currentIndex = (currentIndex + 1) % totalSlides;
      showSlide(currentIndex);
    }
  
    setInterval(nextSlide, 2000);
  });
  