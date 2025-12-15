# CSS Conflicts Report 🎨

## What is a CSS Conflict?

Imagine you have **two rules** for the same thing. Like if you tell your friend "wear a red shirt" in one message and "wear a blue shirt" in another message. The computer gets confused! It doesn't know which one to follow.

That's what's happening in our CSS files. We have the **same class name in different files** with **different styles**. This is BAD! 🚫

---

## The Problems We Found 🔴

### 1. `.form-group` - THE BIGGEST PROBLEM

**Where?** In 5 different files:

- `components/_forms.scss`
- `components/_personal_info.scss`
- `pages/_devise.scss`
- `pages/_event_form.scss` (appears 2 times!)

**Why is this bad?**
When you write a form (like a login box), the `.form-group` class controls:

- How much space is between fields
- Font size
- Colors
- Margins and padding

But we wrote it **5 different times**! So sometimes forms look one way, sometimes they look another way. **Super confusing!** 😕

**Real example:**

- In the personal info page: form spacing is 15px
- In the event form page: form spacing might be different!
- Users see ugly, broken forms

---

### 2. `.form-label` - Also Broken

**Where?** In 3 files:

- `components/_forms.scss`
- `components/_personal_info.scss`

**Why is this bad?**
Labels are the text like "Email:", "Password:", etc. We defined them TWICE! So sometimes they're big, sometimes they're small. Labels look messy. 😬

---

### 3. `.avatar-img` - Size Mismatch Problem

**Where?** In 2 files:

- `components/_account_show.scss` → Says: 60px x 60px
- `components/_personal_info.scss` → Says: 100% width (stretch to fill)

**Why is this bad?**
Profile pictures appear **different sizes** on different pages!

- On Account page: tiny 60px picture
- On Personal Info page: HUGE picture that fills the whole box

It looks like a design error. People think the app is broken. 🙅

---

### 4. `.page-header` - Title Confusion

**Where?** In 2 files:

- `components/_account_show.scss`
- `components/_personal_info.scss`

**Why is this bad?**
Page titles (like "My Account", "My Profile") might be:

- Different sizes
- Different colors
- Different positions

The app looks messy and unprofessional. ❌

---

### 5. `.avatar` - Three Different Versions

**Where?** In 3+ places:

- `components/_avatar.scss` → Base avatar (40px circle)
- `components/_navbar.scss` → Navbar avatar (40px, but styled differently!)
- `pages/_home.scss` → Home page avatar (maybe different?)

**Why is this bad?**
Profile pictures look different everywhere!

- In the top menu: one style
- On the home page: different style
- It's confusing for users

They think different pictures = different accounts! 🤔

---

### 6. `.profile-btn` - Button Style Issues

**Where?** In 2+ files

**Why is this bad?**
Profile buttons (clickable things to go to your profile) might:

- Be different sizes
- Have different colors
- Have different hover effects

Users click buttons and don't know what's happening! 😕

---

## Why We MUST Fix This 🛠️

### Without fixing:

❌ Forms look broken and messy
❌ Pictures are different sizes everywhere
❌ Buttons look different
❌ Users think the app is broken
❌ New developers get confused
❌ Hard to update styles later

### After we fix:

✅ All forms look the SAME everywhere
✅ All pictures are the SAME size
✅ All buttons look professional
✅ App looks polished and clean
✅ Easy to update later
✅ Users trust the app

---

## How to Fix It (Simple Explanation)

**The Solution:** Put all the **same rules in ONE file**!

Instead of:

```
.form-group {width: 100%} in file 1
.form-group {width: 80%} in file 3
.form-group {width: 90%} in file 5
```

Do this:

```
.form-group {width: 100%} in ONE file ONLY
```

Then every form looks the same. Problem solved! ✨

---

## List of What Needs to Be Fixed

| Problem                         | Found In           | Fix                                            |
| ------------------------------- | ------------------ | ---------------------------------------------- |
| `.form-group` appears 5 times   | Multiple files     | Keep ONLY in `_forms.scss`, delete from others |
| `.form-label` appears 3 times   | Multiple files     | Keep ONLY in `_forms.scss`, delete from others |
| `.avatar-img` appears 2 times   | Different sizes    | Create one standard size, use in all files     |
| `.page-header` appears 2 times  | Different styles   | Keep ONE style only                            |
| `.avatar` appears 3+ times      | Different contexts | Create ONE avatar file with all sizes          |
| `.profile-btn` appears 2+ times | Different styles   | Keep ONE button style                          |

---

## Summary 📝

**We have duplicate CSS classes that make the app look broken.**

**We need to combine them into ONE place so everything looks the same.**

**This is called "code cleanup" and it makes the app look professional.** 🎯
