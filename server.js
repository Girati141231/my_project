// 📦 นำเข้า dependencies ที่จำเป็น
const express = require("express"); // สำหรับสร้าง Web Server
const mongoose = require("mongoose"); // สำหรับเชื่อมต่อ MongoDB
const bcrypt = require("bcryptjs"); // สำหรับเข้ารหัสรหัสผ่าน
const jwt = require("jsonwebtoken"); // สำหรับสร้างและตรวจสอบ Token
const cors = require("cors"); // สำหรับเปิดใช้งาน Cross-Origin Resource Sharing

const app = express(); // สร้าง Express application
app.use(express.json()); // Middleware สำหรับแปลง request body ให้เป็น JSON
app.use(cors({ origin: "*", methods: "GET,POST,PUT,DELETE", allowedHeaders: "Content-Type,Authorization" })); // อนุญาตให้ frontend เรียก API ได้จากทุก origin

// 🔌 เชื่อมต่อ MongoDB
mongoose.connect("mongodb://127.0.0.1:27017/flutter_db", {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});
// 👤 สร้าง schema สำหรับผู้ใช้ (User)
const UserSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ["company", "intern"], required: true },
});

const User = mongoose.model("User", UserSchema);

// 📌 สร้าง schema สำหรับโพสต์ฝึกงาน (Post)
const PostSchema = new mongoose.Schema({
  position: { type: String, required: true },
  description: { type: String, required: true },
  skills: { type: [String], required: true },
  companyId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

const Post = mongoose.model("Post", PostSchema);

// 📨 สร้าง schema สำหรับใบสมัครฝึกงาน (Application)
const ApplicationSchema = new mongoose.Schema({
  postId: { type: mongoose.Schema.Types.ObjectId, ref: "Post", required: true },
  internId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  resume: String,
  coverLetter: String,
  status: { type: String, enum: ["pending", "accepted", "rejected"], default: "pending" },
  appliedAt: { type: Date, default: Date.now },
});

const Application = mongoose.model("Application", ApplicationSchema);

// 🔐 Middleware สำหรับตรวจสอบ JWT token
const verifyToken = (req, res, next) => {
  const token = req.headers["authorization"];
  if (!token) return res.status(403).json({ msg: "No token provided" });

  jwt.verify(token.replace("Bearer ", ""), "SECRET_KEY", (err, decoded) => {
    if (err) return res.status(401).json({ msg: "Unauthorized" });
    req.userId = decoded.id; // บันทึก userId ลงใน req
    req.role = decoded.role; // บันทึก role ลงใน req
    next();  // ไปต่อ
  });
};

// 📝 API: สมัครสมาชิก
app.post("/register", async (req, res) => {
  try {
    const { email, password, role } = req.body;
    const existingUser = await User.findOne({ email }); // ไปอ่านอีเมลในฐานข้อมูล
    if (existingUser) return res.status(400).json({ msg: "Email already exists" }); //ถ้ามีเมลซ้ำให้แจ้ง

    const hashedPassword = await bcrypt.hash(password, 10);//เอารหัสที่สร้างไปเข้ารหัส
    const newUser = new User({ email, password: hashedPassword, role });//สร้างuserใหม่
    await newUser.save();

    res.status(201).json({ msg: "User registered successfully" });
  } catch (error) {
    res.status(500).json({ msg: "Server error" });
  }
});
// 🔑 API: ล็อกอิน
app.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });//หารหัสที่สมัครไว้โดยใช้เมล
    if (!user) return res.status(400).json({ msg: "User not found" });

    const isMatch = await bcrypt.compare(password, user.password);//เทียบรหัสที่ส่งมากับในฐานข้อมูลว่าตรงกันไหม
    if (!isMatch) return res.status(400).json({ msg: "Invalid credentials" });

    const token = jwt.sign({ id: user._id, role: user.role }, "SECRET_KEY", { expiresIn: "1h" });

    res.json({ token, role: user.role, userId: user._id });
  } catch (error) {
    res.status(500).json({ msg: "Server error" });
  }
});
// 📥 API: ดึงโพสต์ทั้งหมด
app.get("/api/posts", async (req, res) => {
  try {
    const posts = await Post.find()
      .populate("companyId", "email")//เอาเมลมาดูว่าใครโพส
      .exec();
    res.json(posts);
  } catch (error) {
    res.status(500).json({ msg: "Server error" });
  }
});

// ➕ API: บริษัทสร้างโพสต์ใหม่
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
      companyId: req.userId,
    });

    await newPost.save();
    res.status(201).json({ msg: "Post created" });
  } catch (error) {
    res.status(500).json({ msg: "Server error" });
  }
});

// ✏️ API: แก้ไขโพสต์
app.put("/api/posts/:id", verifyToken, async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);//เช็คว่าโพสที่แก้มีจริงไหม
    if (!post) return res.status(404).json({ msg: "Post not found" });

    if (post.companyId.toString() !== req.userId)//คนที่จะแก้ได้ต้องเป็นเจ้าของโพส
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

// ❌ API: ลบโพสต์
app.delete("/api/posts/:id", verifyToken, async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);//เช็คว่าโพสที่ลบมีจริงไหม
    if (!post) return res.status(404).json({ msg: "Post not found" });

    if (String(post.companyId) !== String(req.userId)) {//คนที่จะลบได้ต้องเป็นเจ้าของโพส
      return res.status(403).json({ msg: "You are not authorized to delete this post" });
    }

    await post.deleteOne();
    res.status(200).json({ msg: "Post deleted successfully" });
  } catch (error) {
    res.status(500).json({ msg: "Server error", error: error.message });
  }
});

// 📤 API: Intern สมัครฝึกงาน
app.post("/api/applications", verifyToken, async (req, res) => {
  try {
    if (req.role !== "intern")
      return res.status(403).json({ msg: "Only interns can apply" });

    const { postId, resume, coverLetter } = req.body;

    const application = new Application({
      postId,
      internId: req.userId,
      resume,
      coverLetter,
    });

    await application.save();
    res.status(201).json({ msg: "Application submitted successfully" });
  } catch (error) {
    res.status(500).json({ msg: "Server error", error: error.message });
  }
});

// 1️⃣ API ให้ Intern ดูสถานะการสมัครของตัวเอง
app.get("/api/intern/applications", verifyToken, async (req, res) => {
  try {
    if (req.role !== "intern") return res.status(403).json({ msg: "Only interns can view applications" });

    const applications = await Application.find({ internId: req.userId }).populate("postId", "position companyId");//อ่านใบสมัครของตัวเอง

    res.json(applications);
  } catch (error) {
    res.status(500).json({ msg: "Server error", error: error.message });
  }
});

// 1️⃣ API สำหรับให้บริษัทดูใบสมัครที่เข้ามาในโพสต์ของตัวเอง
app.get("/api/company/applications", verifyToken, async (req, res) => {
  try {
    if (req.role !== "company") {
      return res.status(403).json({ msg: "Only companies can view applications" });
    }

    // ดีบักเพื่อให้เห็นข้อมูล userId ที่ใช้งาน
    console.log("User ID (company):", req.userId);

    // ดึงข้อมูลใบสมัครที่เชื่อมโยงกับโพสต์ของบริษัท
    const applications = await Application.find()
      .populate({
        path: "postId",
        match: { companyId: req.userId },  // กรองให้แค่โพสต์ที่บริษัทสร้าง
        select: "position companyId",
      })
      .populate("internId", "email")  // เพื่อให้แสดงข้อมูลของ Intern ที่สมัคร
      .exec();

    // กรองใบสมัครที่บริษัทไม่ได้สร้าง (โพสต์เป็น null)
    const filteredApplications = applications.filter(app => app.postId !== null);

    // ดีบักเพื่อแสดงใบสมัครที่ดึงมา
    console.log("Filtered Applications:", filteredApplications);

    res.json(filteredApplications);
  } catch (error) {
    console.log("Error:", error.message);  // ดีบักข้อผิดพลาด
    res.status(500).json({ msg: "Server error", error: error.message });
  }
});


// 2️⃣ API สำหรับให้บริษัทอัพเดตสถานะของใบสมัคร
app.put("/api/company/applications/:applicationId", verifyToken, async (req, res) => {
  try {
    if (req.role !== "company") return res.status(403).json({ msg: "Only companies can update applications" });

    const { status } = req.body;  // รับสถานะที่ต้องการอัพเดต
    if (!["pending", "accepted", "rejected"].includes(status)) {
      return res.status(400).json({ msg: "Invalid status" });
    }

    const application = await Application.findById(req.params.applicationId);//ใบสมัครมีจริงไหม
    if (!application) return res.status(404).json({ msg: "Application not found" });

    // ตรวจสอบว่าโพสต์นี้เป็นโพสต์ที่บริษัทของผู้ใช้สร้างหรือไม่
    const post = await Post.findById(application.postId);
    if (post.companyId.toString() !== req.userId) {
      return res.status(403).json({ msg: "You are not authorized to update this application" });
    }

    // อัพเดตสถานะของใบสมัคร
    application.status = status;
    await application.save();

    res.json({ msg: "Application status updated successfully" });
  } catch (error) {
    res.status(500).json({ msg: "Server error", error: error.message });
  }
});


app.listen(5000, () => {
  console.log("Server is running on port 5000");
});
















