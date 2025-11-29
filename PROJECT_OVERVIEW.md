# Park-Pro Project: Comprehensive Technical Overview

## Project Overview
Park-Pro is a comprehensive smart parking management system that integrates IoT sensors, AI-powered chatbots, mobile applications, and web interfaces to provide seamless parking solutions. The system enables users to find, book, and pay for parking spots while offering station administrators tools for management.

## Architecture Overview

### System Components
1. **Backend API (Node.js/Express)** - Core business logic and database operations
2. **AI Service (Python/FastAPI)** - Intelligent chatbot and automation
3. **Mobile App (Flutter)** - User-facing mobile application
4. **Web Frontend (HTML/CSS/JS)** - Administrative and user web interfaces
5. **IoT Layer (Arduino)** - Smart parking sensors and hardware integration
6. **Database (MongoDB)** - Data persistence and management

### Technology Stack

#### Backend (Node.js) - package.json Dependencies
**Core Framework & Runtime:**
- **express (^4.18.2)**: Web application framework for Node.js, handles HTTP requests, routing, and middleware. Provides robust API development capabilities with middleware support.
- **mongoose (^8.13.2)**: MongoDB object modeling for Node.js, provides schema validation, data modeling, and query building. Enables structured data operations with MongoDB.
- **mongodb (^6.15.0)**: Official MongoDB driver for Node.js, handles direct database connections and operations.

**Authentication & Security:**
- **bcryptjs (^3.0.2)**: Password hashing library for secure password storage. Uses Blowfish cipher to hash passwords with salt, preventing rainbow table attacks.
- **jsonwebtoken (^9.0.2)**: Implementation of JSON Web Tokens for stateless authentication. Creates and verifies JWT tokens for secure API access.
- **passport (^0.6.0)**: Authentication middleware for Node.js with multiple strategies. Provides flexible authentication framework.
- **passport-google-oauth20 (^2.0.0)**: Google OAuth 2.0 authentication strategy for Passport. Enables Google social login integration.
- **passport-jwt (^4.0.1)**: Passport strategy for authenticating with JSON Web Tokens. Handles JWT token validation in requests.

**Payment Processing:**
- **razorpay (^2.9.6)**: Official Node.js SDK for Razorpay payment gateway integration. Handles payment orders, verification, and refunds for Indian payments.
- **stripe (^14.17.0)**: Official Stripe Node.js library for payment processing. Provides global payment processing capabilities with webhooks.

**File Upload & Cloud Storage:**
- **multer (^1.4.5-lts.1)**: Middleware for handling multipart/form-data (file uploads). Processes file uploads in Express applications.
- **multer-storage-cloudinary (^4.0.0)**: Cloudinary storage engine for Multer. Integrates Cloudinary cloud storage with Multer for image uploads.
- **cloudinary (^1.41.3)**: Cloud image management and manipulation. Provides image upload, transformation, and delivery services.

**Communication & Utilities:**
- **nodemailer (^7.0.6)**: Email sending library for Node.js. Handles SMTP email sending for notifications and confirmations.
- **cors (^2.8.5)**: Cross-Origin Resource Sharing middleware. Enables cross-origin requests between frontend and backend.
- **express-session (^1.18.1)**: Session middleware for Express. Manages user sessions for authentication state.
- **dotenv (^16.5.0)**: Environment variable loading from .env files. Secures sensitive configuration data.
- **google-auth-library (^9.15.1)**: Google authentication library. Supports Google OAuth and service account authentication.

**Development Tools:**
- **nodemon (^3.1.9)**: Utility that monitors for changes and automatically restarts the server. Improves development workflow.

#### AI Service (Python) - requirements.txt Dependencies
**Web Framework:**
- **fastapi (0.104.1)**: Modern, fast web framework for building APIs with Python 3.7+. Provides automatic API documentation and async support.
- **uvicorn (0.24.0)**: ASGI web server implementation for Python. High-performance server for running FastAPI applications.

**Data Processing & NLP:**
- **nltk (3.8.1)**: Natural Language Toolkit for natural language processing tasks. Provides tokenization, stemming, and text processing capabilities.

**Database & External APIs:**
- **pymongo (4.6.0)**: Python driver for MongoDB. Enables MongoDB operations from Python applications.
- **requests (2.31.0)**: HTTP library for Python. Handles HTTP requests to external APIs and backend services.

**Authentication & Security:**
- **pyjwt (2.8.0)**: Python implementation of JSON Web Tokens. Creates and verifies JWT tokens for API authentication.
- **python-dotenv (1.0.0)**: Reads key-value pairs from .env files. Manages environment variables securely.

#### Mobile App (Flutter) - pubspec.yaml Dependencies
**Core Framework:**
- **flutter**: Google's UI toolkit for building natively compiled applications. Provides widgets and tools for cross-platform development.
- **flutter_test**: Testing framework for Flutter applications. Enables unit and widget testing.

**UI & Design:**
- **cupertino_icons**: iOS-style icons for Flutter applications. Provides native iOS iconography.

**Payment Integration:**
- **razorpay_flutter (^1.3.7)**: Official Flutter SDK for Razorpay. Enables payment processing within Flutter mobile apps.

**HTTP & Networking:**
- **http (^0.13.6)**: HTTP client for Dart/Flutter. Handles REST API calls and HTTP requests.

**State Management & Storage:**
- **shared_preferences (^2.0.15)**: Persistent storage for simple data. Stores key-value pairs locally on device.
- **intl (^0.19.0)**: Internationalization library for Flutter. Handles localization and date/time formatting.

**Maps & Location Services:**
- **flutter_map (^4.0.0)**: Flutter mapping library. Displays interactive maps with various tile providers.
- **latlong2 (^0.8.1)**: Lightweight library for latitude/longitude calculations. Handles geographic coordinates.
- **geolocator (^9.0.2)**: Geolocation plugin for Flutter. Provides location services and GPS functionality.
- **geocoding (^2.0.5)**: Geocoding and reverse geocoding services. Converts coordinates to addresses and vice versa.

**Speech & Accessibility:**
- **speech_to_text (^7.3.0)**: Speech-to-text plugin for Flutter. Converts speech input to text.
- **flutter_tts (^4.2.3)**: Text-to-speech plugin for Flutter. Converts text to spoken audio.

**File & Media Handling:**
- **image_picker (^1.0.4)**: Image picker plugin for Flutter. Allows users to select images from gallery or camera.
- **uuid (^4.4.0)**: UUID generator for Dart. Creates unique identifiers for various purposes.

**Permissions:**
- **permission_handler (^12.0.1)**: Permission handler for Flutter. Manages app permissions for location, camera, etc.

**Development Tools:**
- **flutter_launcher_icons (^0.13.1)**: Package for generating app icons. Creates platform-specific launcher icons.

#### Web Frontend - Dependencies (Vanilla JS)
**Core Technologies:**
- **HTML5**: Markup language for structuring web content
- **CSS3**: Styling language for visual presentation
- **Vanilla JavaScript (ES6+)**: Programming language for interactive functionality

**Key Libraries & Frameworks:**
- **Custom CSS Framework**: Responsive design system with mobile-first approach
- **JWT Authentication**: Client-side token management for API authentication
- **RESTful API Integration**: Direct HTTP calls to backend services
- **Payment SDKs**: Razorpay and Stripe JavaScript SDKs for web payments
- **Geolocation API**: Browser-based location services
- **Local Storage/Session Storage**: Client-side data persistence

#### IoT Layer - Dependencies
**Hardware:**
- **Arduino IDE**: Development environment for Arduino programming
- **Arduino Libraries**: Standard libraries for sensor communication and control

**Software:**
- **Serial Communication**: UART protocol for data transmission
- **WebSocket/HTML5**: Real-time dashboard communication
- **JavaScript**: Client-side dashboard functionality
- **HTML/CSS**: Dashboard user interface

## Database Schema

### Core Models
- **User**: User profiles, authentication, roles (admin, station_admin, user)
- **Station**: Parking stations with location, pricing, slots
- **Slot**: Individual parking spaces with availability status
- **SlotBooking**: Booking records with payment details
- **Vehicle**: User vehicles for booking association
- **Payment**: Transaction records
- **Review**: User feedback and ratings
- **Notification**: System notifications
- **Contact**: User inquiries
- **Media**: File uploads (images, documents)
- **FastagTransaction**: Toll payment records
- **Register**: Registration requests for new stations

## Key Features

### User Features
1. **Smart Parking Search**: GPS-based location services
2. **Real-time Availability**: Live slot status updates
3. **AI Chatbot**: Voice and text-based assistance
4. **Secure Payments**: Multiple payment gateways
5. **Booking Management**: View, modify, cancel bookings
6. **Vehicle Management**: Add/manage multiple vehicles
7. **FASTag Integration**: Toll payment automation
8. **Notifications**: Real-time booking updates
9. **Reviews & Ratings**: Station feedback system

### Administrative Features
1. **Station Management**: Add/edit parking stations
2. **Slot Configuration**: Dynamic slot management
3. **User Management**: Admin panel for users
4. **Analytics**: Booking and revenue reports
5. **Payment Processing**: Transaction monitoring
6. **Review Moderation**: Content management

### AI Features
1. **Intent Recognition**: Natural language understanding
2. **Contextual Responses**: Session-based conversations
3. **Automated Booking**: Voice-guided reservations
4. **Smart Suggestions**: Personalized recommendations
5. **Multi-language Support**: Translation capabilities

## API Endpoints

### Authentication Routes
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `GET /api/auth/google` - Google OAuth
- `POST /api/auth/logout` - User logout

### Station Routes
- `GET /api/stations` - List all stations
- `POST /api/stations` - Create new station (admin)
- `GET /api/stations/:id` - Get station details
- `PUT /api/stations/:id` - Update station (admin)

### Slot Routes
- `GET /api/slots/station/:stationId` - Get station slots
- `POST /api/slots/book` - Create booking
- `PUT /api/slots/:id/status` - Update slot status

### User Routes
- `GET /api/user/profile` - Get user profile
- `PUT /api/user/profile` - Update profile
- `GET /api/user/bookings` - Get user bookings
- `GET /api/user/vehicles` - Get user vehicles

### AI Routes
- `POST /api/chat` - Chat with AI assistant
- `POST /api/process_intent` - Process specific intents

## Security Implementation

### Authentication & Authorization
- JWT tokens with expiration
- Role-based access control (RBAC)
- Password hashing with bcrypt
- Session management
- CORS configuration

### Data Protection
- Input validation and sanitization
- SQL injection prevention (MongoDB)
- XSS protection
- Secure file uploads
- Environment variable management

## Payment Integration

### Razorpay Integration
- Order creation for bookings
- Payment verification webhooks
- Refund processing
- Multiple currency support

### Stripe Integration
- Alternative payment gateway
- Subscription management
- Webhook handling

## IoT Integration

### Hardware Components
- Arduino microcontroller
- Ultrasonic sensors for parking detection
- LED indicators for slot status
- Serial communication interface

### Software Integration
- Real-time data transmission
- Sensor calibration
- Dashboard visualization
- Alert system for maintenance

## Deployment & DevOps

### Development Setup
```bash
# Backend
cd backend && npm install && npm run dev

# AI Service
cd ai_service && python -m venv venv && pip install -r requirements.txt && python run.py

# Flutter App
cd park-pro-application && flutter pub get && flutter run

# Web Frontend
# Served statically from backend on port 5000
```

### Environment Configuration
- `.env` files for sensitive data
- Database connection strings
- API keys (OpenAI, payment gateways)
- CORS origins configuration

### Production Considerations
- Docker containerization
- Load balancing
- Database clustering
- CDN for static assets
- SSL/TLS certificates

## Current Development Status

### Completed Features
- ✅ User authentication (JWT + Google OAuth)
- ✅ Station and slot management
- ✅ Basic booking system
- ✅ Razorpay payment integration
- ✅ AI chatbot with intent recognition
- ✅ Flutter mobile app
- ✅ Web admin dashboard
- ✅ IoT sensor integration
- ✅ FASTag toll payment system

### In Progress (TODO)
- 🔄 Razorpay webhook integration
- 🔄 UPI payment completion
- 🔄 Toll payment automation
- 🔄 Advanced AI features (ML classifier)

## Challenges & Solutions

### Technical Challenges
1. **Real-time Updates**: Solved with WebSocket integration and polling
2. **GPS Accuracy**: Implemented geolocation services with error handling
3. **Payment Security**: Multiple gateway support with verification
4. **AI Accuracy**: Rule-based system with NLTK, planned ML upgrade
5. **Cross-platform Compatibility**: Flutter for unified mobile development

### Business Challenges
1. **User Adoption**: Intuitive UI/UX design
2. **Competition**: Differentiated with AI and IoT features
3. **Scalability**: Microservices architecture
4. **Security**: Comprehensive security measures

## Future Roadmap

### Short-term (3-6 months)
- ML-based AI chatbot
- Advanced analytics dashboard
- Mobile wallet integration
- Multi-language support

### Long-term (6-12 months)
- Predictive parking availability
- Autonomous vehicle integration
- Smart city partnerships
- Global expansion

## Interview Preparation Notes

### Key Technologies to Highlight
- Full-stack development (Node.js, Python, Flutter)
- Microservices architecture
- IoT integration
- AI/ML implementation
- Payment gateway integration
- Real-time systems

### Architecture Decisions
- Why Node.js for backend? Scalability, JavaScript ecosystem
- Why FastAPI for AI? High performance, async support
- Why Flutter? Cross-platform, single codebase
- Why MongoDB? Flexible schema, JSON-like documents

### Scalability Considerations
- Horizontal scaling with load balancers
- Database sharding for large datasets
- Caching layers (Redis planned)
- CDN for global distribution

### Security Best Practices
- JWT for stateless auth
- Input validation
- HTTPS everywhere
- Regular security audits
- Data encryption at rest

This comprehensive overview covers the Park-Pro project from architecture to implementation details, providing a solid foundation for technical interview discussions.
