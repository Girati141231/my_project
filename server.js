const express = require("express");
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const cors = require("cors");

const app = express();
app.use(express.json());
app.use(cors({ origin: "*", methods: "GET,POST,PUT,DELETE", allowedHeaders: "Content-Type,Authorization" }));

mongoose.connect("mongodb://127.0.0.1:27017/flutter_db", {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

const UserSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ["company", "intern"], required: true },
});

const User = mongoose.model("User", UserSchema);

const PostSchema = new mongoose.Schema({
  position: { type: String, required: true },
  description: { type: String, required: true },
  skills: { type: [String], required: true },
  companyId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

const Post = mongoose.model("Post", PostSchema);

// Middleware to verify token
const verifyToken = (req, res, next) => {
  const token = req.headers["authorization"];
  if (!token) return res.status(403).json({ msg: "No token provided" });

  jwt.verify(token.replace("Bearer ", ""), "SECRET_KEY", (err, decoded) => {
    if (err) return res.status(401).json({ msg: "Unauthorized" });
    req.userId = decoded.id;
    req.role = decoded.role;
    next();
  });
};

// Registration API
app.post("/register", async (req, res) => {
  try {
    const { email, password, role } = req.body;
    const existingUser = await User.findOne({ email });
    if (existingUser) return res.status(400).json({ msg: "Email already exists" });

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = new User({ email, password: hashedPassword, role });
    await newUser.save();

    res.status(201).json({ msg: "User registered successfully" });
  } catch (error) {
    res.status(500).json({ msg: "Server error" });
  }
});

// Login API
app.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ msg: "User not found" });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ msg: "Invalid credentials" });

    const token = jwt.sign({ id: user._id, role: user.role }, "SECRET_KEY", { expiresIn: "1h" });

    res.json({ token, role: user.role, userId: user._id });
  } catch (error) {
    res.status(500).json({ msg: "Server error" });
  }
});

// Fetch all posts
app.get("/api/posts", async (req, res) => {
  try {
    const posts = await Post.find().populate("companyId", "email");
    res.json(posts);
  } catch (error) {
    res.status(500).json({ msg: "Server error" });
  }
});

// Add a post
app.post("/api/posts", verifyToken, async (req, res) => {
  try {
    const { position, description, skills } = req.body;

    if (!position || !description || !skills) {
      return res.status(400).json({ msg: "All fields are required" });
    }

    const newPost = new Post({
      position,
      description,
      skills,
      companyId: req.userId // Using the user ID from the token
    });

    await newPost.save();
    res.status(201).json({ msg: "Post created" });
  } catch (error) {
    res.status(500).json({ msg: "Server error" });
  }
});

// Edit a post
app.put("/api/posts/:id", verifyToken, async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ msg: "Post not found" });

    if (post.companyId.toString() !== req.userId)
      return res.status(403).json({ msg: "You are not authorized to edit this post" });

    const { position, description, skills } = req.body;

    post.position = position;
    post.description = description;
    post.skills = skills;
    post.updatedAt = Date.now();

    await post.save();
    res.status(200).json({ msg: "Post updated" });
  } catch (error) {
    res.status(500).json({ msg: "Server error" });
  }
});

// Delete a post
app.delete("/api/posts/:id", verifyToken, async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ msg: "Post not found" });

    if (post.companyId.toString() !== req.userId)
      return res.status(403).json({ msg: "You are not authorized to delete this post" });

    await post.remove();
    res.status(200).json({ msg: "Post deleted successfully" });
  } catch (error) {
    res.status(500).json({ msg: "Server error" });
  }
});

app.listen(5000, () => {
  console.log("Server is running on port 5000");
});















